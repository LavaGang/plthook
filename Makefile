BUILD_DIR := build/$(TARGET)

CFLAGS := -O2 -Wall -Wextra
CPPFLAGS := -I. -MMD -MP
ARFLAGS := rcs

ifeq ($(TARGET),linux-x86)

CC := clang
AR := ar

SOURCE := plthook_elf.c
LIB := $(BUILD_DIR)/libplthook.a

TARGET_CFLAGS := -m32 --target=i686-pc-linux-gnu

else ifeq ($(TARGET),linux-x64)

CC := clang
AR := ar

SOURCE := plthook_elf.c
LIB := $(BUILD_DIR)/libplthook.a

TARGET_CPPFLAGS := -DAMD64
TARGET_CFLAGS := --target=x86_64-pc-linux-gnu

else ifeq ($(TARGET),linux-arm64)

CC := clang
AR := ar

SOURCE := plthook_elf.c
LIB := $(BUILD_DIR)/libplthook.a

TARGET_CPPFLAGS := -DARM64
TARGET_CFLAGS := --target=arm64-pc-linux-gnu

else ifeq ($(TARGET),win-x86)

CC := clang
AR := ar

SOURCE := plthook_win32.c
LIB := $(BUILD_DIR)/plthook.lib

TARGET_CPPFLAGS := -DWIN32 -D_WIN32
TARGET_CFLAGS := --target=i686-pc-windows-msvc

else ifeq ($(TARGET),win-x64)

CC := clang
AR := ar

SOURCE := plthook_win32.c
LIB := $(BUILD_DIR)/plthook.lib

TARGET_CPPFLAGS := -DWIN32 -D_WIN32 -DAMD64
TARGET_CFLAGS := --target=x86_64-pc-windows-msvc

else ifeq ($(TARGET),win-arm64)

CC := clang
AR := ar

SOURCE := plthook_win32.c
LIB := $(BUILD_DIR)/plthook.lib

TARGET_CPPFLAGS := -DWIN32 -D_WIN32 -DARM64
TARGET_CFLAGS := --target=arm64-pc-windows-msvc

else ifeq ($(TARGET),osx-x64)

CC := clang
AR := ar

SOURCE := plthook_osx.c
LIB := $(BUILD_DIR)/libplthook.a

TARGET_CPPFLAGS := -DAMD64 -mmacosx-version-min=12.0
TARGET_CFLAGS := --target=x86_64-apple-darwin

else ifeq ($(TARGET),osx-arm64)

CC := clang
AR := ar

SOURCE := plthook_osx.c
LIB := $(BUILD_DIR)/libplthook.a

TARGET_CPPFLAGS := -DARM64 -mmacosx-version-min=12.0
TARGET_CFLAGS := --target=arm64-apple-darwin

else ifneq ($(TARGET),all)

$(error Unknown TARGET '$(TARGET)')

endif

OBJECT := $(BUILD_DIR)/$(SOURCE:.c=.o)
DEPFILE := $(OBJECT:.o=.d)

$(LIB): $(OBJECT)
	@echo "AR $@"
	@mkdir -p "$(BUILD_DIR)"
	$(AR) $(ARFLAGS) "$@" "$^"

$(OBJECT): $(SOURCE) plthook.h
	@echo "CC $@"
	@mkdir -p "$(BUILD_DIR)"
	$(CC) $(CPPFLAGS) $(TARGET_CPPFLAGS) \
	      $(CFLAGS) $(TARGET_CFLAGS) \
	      -c "$<" -o "$@"

-include $(DEPFILE)

.PHONY: \
	$(BUILD_DIR)

linux-x86:
	$(MAKE) TARGET=linux-x86

linux-x64:
	$(MAKE) TARGET=linux-x64

linux-arm64:
	$(MAKE) TARGET=linux-arm64

win-x86:
	$(MAKE) TARGET=win-x86

win-x64:
	$(MAKE) TARGET=win-x64

win-arm64:
	$(MAKE) TARGET=win-arm64

osx-x64:
	$(MAKE) TARGET=osx-x64

osx-arm64:
	$(MAKE) TARGET=osx-arm64

all:
	$(MAKE) TARGET=linux-x86
	$(MAKE) TARGET=linux-x64
	$(MAKE) TARGET=linux-arm64
	$(MAKE) TARGET=win-x86
	$(MAKE) TARGET=win-x64
	$(MAKE) TARGET=win-arm64
	$(MAKE) TARGET=osx-x64
	$(MAKE) TARGET=osx-arm64

clean:
	rm -rf build
