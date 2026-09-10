/* Include the implementation to exercise malformed files without asking dyld
 * to load them, and to check CPU subtypes unavailable on the test machine. */
#include "../plthook_osx.c"
#include <assert.h>

static uint32_t encode32(uint32_t value, int swap) {
	return swap ? OSSwapInt32(value) : value;
}

static uint64_t encode64(uint64_t value, int swap) {
	return swap ? OSSwapInt64(value) : value;
}

static FILE *fixture(int is64, int swap, cpu_type_t cpu, cpu_subtype_t subtype, uint64_t offset, uint64_t size) {
	FILE *fp = tmpfile();
	assert(fp != NULL);
	struct fat_header header = {encode32(is64 ? FAT_MAGIC_64 : FAT_MAGIC, swap), encode32(2, swap)};
	assert(fwrite(&header, sizeof(header), 1, fp) == 1);
	for (int i = 0; i < 2; i++) {
		/* The first entry deliberately has the right CPU but wrong subtype. */
		uint32_t sub = i == 0 ? (uint32_t)subtype ^ 1 : (uint32_t)subtype;
		if (is64) {
			struct fat_arch_64 arch = {encode32(cpu, swap), encode32(sub, swap),
				encode64(offset, swap), encode64(size, swap), 0, 0};
			assert(fwrite(&arch, sizeof(arch), 1, fp) == 1);
		} else {
			struct fat_arch arch = {encode32(cpu, swap), encode32(sub, swap),
				encode32(offset, swap), encode32(size, swap), 0};
			assert(fwrite(&arch, sizeof(arch), 1, fp) == 1);
		}
	}
	assert(fseeko(fp, 511, SEEK_SET) == 0);
	assert(fputc(0, fp) == 0);
	assert(fflush(fp) == 0);
	return fp;
}

int main(void) {
	struct mach_header mh = {0};
	mh.magic = MH_MAGIC_64;
	for (int cpu = 0; cpu < 2; cpu++) {
		mh.cputype = cpu ? CPU_TYPE_ARM64 : CPU_TYPE_X86_64;
		mh.cpusubtype = cpu ? CPU_SUBTYPE_ARM64_ALL : CPU_SUBTYPE_X86_64_ALL;
		for (int is64 = 0; is64 < 2; is64++) {
			for (int swap = 0; swap < 2; swap++) {
				off_t offset = -1, size = -1;
				FILE *fp = fixture(is64, swap, mh.cputype, mh.cpusubtype, 256, 256);
				assert(get_macho_slice(fp, &mh, &offset, &size) == 0);
				assert(offset == 256 && size == 256);
				mh.cpusubtype ^= 2;
				assert(get_macho_slice(fp, &mh, &offset, &size) == PLTHOOK_INVALID_FILE_FORMAT);
				mh.cpusubtype ^= 2;
				mh.cputype = CPU_TYPE_POWERPC;
				assert(get_macho_slice(fp, &mh, &offset, &size) == PLTHOOK_INVALID_FILE_FORMAT);
				mh.cputype = cpu ? CPU_TYPE_ARM64 : CPU_TYPE_X86_64;
				assert(ftruncate(fileno(fp), sizeof(struct fat_header) + 1) == 0);
				assert(get_macho_slice(fp, &mh, &offset, &size) == PLTHOOK_INVALID_FILE_FORMAT);
				fclose(fp);
				uint64_t invalid[][2] = {{0, 256}, {512, 256}, {256, 257}, {256, 1}, {UINT64_MAX, 256}};
				for (unsigned int i = 0; i < sizeof(invalid) / sizeof(invalid[0]); i++) {
					fp = fixture(is64, swap, mh.cputype, mh.cpusubtype, invalid[i][0], invalid[i][1]);
					assert(get_macho_slice(fp, &mh, &offset, &size) == PLTHOOK_INVALID_FILE_FORMAT);
					fclose(fp);
				}
			}
		}
	}
	FILE *fp = tmpfile();
	assert(fp != NULL);
	off_t offset, size;
	assert(get_macho_slice(fp, &mh, &offset, &size) == PLTHOOK_INVALID_FILE_FORMAT);
	assert(fwrite(&mh, sizeof(mh), 1, fp) == 1);
	assert(fflush(fp) == 0);
	assert(get_macho_slice(fp, &mh, &offset, &size) == 0);
	assert(offset == 0 && size == sizeof(mh));
	assert(fseeko(fp, 0, SEEK_SET) == 0);
	uint32_t invalid_magic = 0;
	assert(fwrite(&invalid_magic, sizeof(invalid_magic), 1, fp) == 1);
	assert(fflush(fp) == 0);
	assert(get_macho_slice(fp, &mh, &offset, &size) == PLTHOOK_INVALID_FILE_FORMAT);
	fclose(fp);
	puts("PASS: Mach-O slice selection and invalid headers");
	return 0;
}
