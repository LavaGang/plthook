#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
#include "plthook.h"

static int replacement(const char *text) {
	(void)text;
	return 12345;
}

int main(int argc, char **argv) {
	if (argc != 3) {
		fprintf(stderr, "usage: %s library open|open_by_handle|open_by_address\n", argv[0]);
		return 1;
	}
	char path[PATH_MAX];
	if (!realpath(argv[1], path)) {
		perror("realpath");
		return 1;
	}
	void *library = dlopen(path, RTLD_NOW | RTLD_LOCAL);
	if (!library) {
		fprintf(stderr, "%s\n", dlerror());
		return 1;
	}
	int (*call)(void) = dlsym(library, "fixture_call");
	if (!call) {
		fprintf(stderr, "%s\n", dlerror());
		return 1;
	}
	plthook_t *hook = NULL;
	int result;
	if (strcmp(argv[2], "open") == 0) {
		result = plthook_open(&hook, path);
	} else if (strcmp(argv[2], "open_by_handle") == 0) {
		result = plthook_open_by_handle(&hook, library);
	} else if (strcmp(argv[2], "open_by_address") == 0) {
		result = plthook_open_by_address(&hook, (void *)call);
	} else {
		return 1;
	}
	if (result != 0) {
		fprintf(stderr, "%s: %s\n", argv[2], plthook_error());
		return 1;
	}
	result = plthook_replace(hook, "puts", replacement, NULL);
	plthook_close(hook);
	if (result != 0) {
		fprintf(stderr, "plthook_replace: %s\n", plthook_error());
		return 1;
	}
	if (call() != 12345) {
		fprintf(stderr, "replacement was not called\n");
		return 1;
	}
	printf("PASS: %s %s\n", argv[1], argv[2]);
	dlclose(library);
	return 0;
}
