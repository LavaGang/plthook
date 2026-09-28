BUILD_DIR := build/$(TARGET)

CFLAGS ?= -O2 -Wall -Wextra
CPPFLAGS ?= -I. -M -MT /MT
ARFLAGS ?= rcs

ifeq ($(TARGET),linux-x86)

CC ?= gcc
AR ?= ar
SOURCE := plthook_elf.c

TARGET_CFLAGS := -m32 -Wl,--version-script,plthook_elf.def

LIB := $(BUILD_DIR)/libplthook.a

else ifeq ($(TARGET),linux-x64)

CC ?= gcc
AR ?= ar
SOURCE := plthook_elf.c

TARGET_CFLAGS := -DAMD64 -Wl,--version-script,plthook_elf.def

LIB := $(BUILD_DIR)/libplthook.a

else ifeq ($(TARGET),linux-arm64)

CC ?= aarch64-linux-gnu-gcc
AR ?= aarch64-linux-gnu-ar
SOURCE := plthook_elf.c

TARGET_CFLAGS := -DARM64 -Wl,--version-script,plthook_elf.def

LIB := $(BUILD_DIR)/libplthook.a

else ifeq ($(TARGET),win-x86)

CC ?= cl
AR ?= lib
SOURCE := plthook_win32.c

TARGET_CFLAGS := -m32
TARGET_CPPFLAGS := -DWIN32 -D_WIN32

LIB := $(BUILD_DIR)/plthook.lib
LIBFLAGS := /DEF:"plthook_win32.def" /IMPLIB:"$(LIB)"

else ifeq ($(TARGET),win-x64)

CC ?= cl
AR ?= lib
SOURCE := plthook_win32.c

TARGET_CFLAGS := -DAMD64
TARGET_CPPFLAGS := -DWIN32 -D_WIN32

LIB := $(BUILD_DIR)/plthook.lib
LIBFLAGS := /DEF:"plthook_win32.def" /IMPLIB:"$(LIB)"

else ifeq ($(TARGET),win-arm64)

CC ?= cl
AR ?= lib
SOURCE := plthook_win32.c

TARGET_CFLAGS := -DARM64
TARGET_CPPFLAGS := -DWIN32 -D_WIN32

LIB := $(BUILD_DIR)/plthook.lib
LIBFLAGS := /DEF:"plthook_win32.def" /IMPLIB:"$(LIB)"

else ifeq ($(TARGET),osx-x64)

CC ?= clang
AR ?= ar
SOURCE := plthook_osx.c

TARGET_CFLAGS := -DAMD64 -exported_symbols_list plthook_osx.def

LIB := $(BUILD_DIR)/libplthook.a

else ifeq ($(TARGET),osx-arm64)

CC ?= clang
AR ?= ar
SOURCE := plthook_osx.c

TARGET_CFLAGS := -DARM64 -exported_symbols_list plthook_osx.def

LIB := $(BUILD_DIR)/libplthook.a

else ifneq ($(TARGET),all)

$(error Unknown TARGET '$(TARGET)')

endif

OBJECT := $(BUILD_DIR)/$(SOURCE:.c=.o)

ifeq ($(TARGET),win-x86)

$(LIB): $(OBJECT)
	@echo " AR $@"
	@mkdir -p "$(BUILD_DIR)"
	$(AR) /OUT:"$@" $(LIBFLAGS) "$<"

else ifeq ($(TARGET),win-x64)

$(LIB): $(OBJECT)
	@echo " AR $@"
	@mkdir -p "$(BUILD_DIR)"
	$(AR) /OUT:"$@" $(LIBFLAGS) "$<"

else ifeq ($(TARGET),win-arm64)

$(LIB): $(OBJECT)
	@echo " AR $@"
	@mkdir -p "$(BUILD_DIR)"
	$(AR) /OUT:"$@" $(LIBFLAGS) "$<"

else

$(LIB): $(OBJECT)
	@echo " AR $@"
	@mkdir -p "$(BUILD_DIR)"
	$(AR) $(ARFLAGS) "$@" "$^"

endif

$(OBJECT): $(SOURCE) plthook.h
	@echo "  CC      $@"
	@mkdir -p "$(BUILD_DIR)"
	$(CC) $(CPPFLAGS) $(TARGET_CPPFLAGS) \
	      $(CFLAGS) $(TARGET_CFLAGS) \
	      -c "$<" -o "$@"

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
	$(MAKE) TARGET=windows-x86
	$(MAKE) TARGET=windows-x64
	$(MAKE) TARGET=windows-arm64
	$(MAKE) TARGET=osx-x64
	$(MAKE) TARGET=osx-arm64

clean:
	rm -rf build
