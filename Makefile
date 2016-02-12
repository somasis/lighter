VERSION			=scm

CFLAGS			?= -Os
CXXFLAGS		?= $(CFLAGS)

CFLAGS			+= -static
LDFLAGS			+= -static

JOBS			?= $(shell expr $$(grep -c processor /proc/cpuinfo) + 4)

LIGHTER			?= $(PWD)
ARCHIVES		?= $(LIGHTER)/archives
BUILD			?= $(LIGHTER)/build
CONFIGS			?= $(LIGHTER)/configs
DOWNLOADS		?= $(LIGHTER)/downloads
TOOLCHAIN		?= $(LIGHTER)/toolchain

PATH			+=:$(TOOLCHAIN)
export CFLAGS
export CXXFLAGS
export LDFLAGS
export JOBS
export LIGHTER
export ARCHIVES
export BUILD
export CONFIGS
export DOWNLOADS
export TOOLCHAIN
export PATH

make            =	\
	busybox=http=//busybox.net/downloads/busybox-1.24.1.tar.bz2					\
	dropbear=https=//matt.ucc.asn.au/dropbear/releases/dropbear-2015.71.tar.bz2

all:
	@printf "lighter $(VERSION)\n\n"
	@printf "%-20s%-20s\n"	\
		"CFLAGS"		"$(CFLAGS)"		\
		"CXXFLAGS"		"$(CXXFLAGS)"	\
		"JOBS"          "$(JOBS)"	\
		"BUILD"			"$(BUILD)"
	@printf "\n"
	@$(MAKE) --no-print-directory buildall

$(BUILD)/.prepare:
	@printf "making build directories...\n"
	@sh -e scripts/prepare
	@printf "\n"

$(BUILD)/.toolchain: $(BUILD)/.prepare
	@printf "making any needed toolchain links...\n"
	@sh -e scripts/toolchain
	@touch "$(BUILD)"/.toolchain
	@printf "\n"

$(BUILD)/.fetch-%: $(BUILD)/.prepare
	@sh -e scripts/fetch "$*"

$(BUILD)/.extract-%: $(BUILD)/.fetch-%
	@sh -e scripts/extract "$*"

$(BUILD)/.build-%: $(BUILD)/.toolchain $(BUILD)/.extract-%
	@sh -e scripts/build "$*"

$(BUILD)/initramfs.cpio.gz:
	cd "$(BUILD)/root" && find . -print0 | cpio --null -ov --format=newc | gzip -9 > "$(BUILD)"/initramfs.cpio.gz

pack:		$(BUILD)/initramfs.cpio.gz
buildall:		$(foreach m,$(make),$(BUILD)/.build-$(m))
build:
	@$(MAKE) --no-print-directory buildall
	@$(MAKE) --no-print-directory pack

clean:
	rm -rf downloads archives $(BUILD) toolchain

.PHONY:		all fetch
