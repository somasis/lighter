VERSION			=scm

CFLAGS			?= -Os
CXXFLAGS		?= $(CFLAGS)

CFLAGS			+= -static
LDFLAGS			+= -static

export CFLAGS
export CXXFLAGS
export LDFLAGS

JOBS			= $$(expr $$(grep -c processor /proc/cpuinfo) + 4)

BUILD			?= $(PWD)/build

PATH			+= :$(PWD)/toolchain

urls            =	\
	http://busybox.net/downloads/busybox-1.24.1.tar.bz2					\
	https://matt.ucc.asn.au/dropbear/releases/dropbear-2015.71.tar.bz2

make			= busybox dropbear

all:
	@printf "lighter $(VERSION)\n\n"
	@printf "%-20s%-20s\n"	\
		"CFLAGS"		"$(CFLAGS)"		\
		"CXXFLAGS"		"$(CXXFLAGS)"	\
		"JOBS"          "$(JOBS)"	\
		"BUILD"			"$(BUILD)"
	@printf "\n"
	@$(MAKE) build

toolchain:
	@printf "making any needed toolchain links...\n"
	@sh -e scripts/toolchain
	@printf "\n"
#	@for d in $(dirs);do echo "mkdir -p $(BUILD)/$$d"; [ -d "$$d" ] || mkdir -p $(BUILD)/"$$d";done

prepare: toolchain skel
	@printf "making build directories...\n"
	-mkdir -p "$(BUILD)" >/dev/null 2>&1
	-mkdir "$(BUILD)"/root >/dev/null 2>&1
	@printf "copying skeleton root to %s...\n" "$(BUILD)"
	cp -r skel/* "$(BUILD)"/root/
	@printf "\n"

fetch: prepare
	@printf "fetching all needed files...\n"
	@sh -e scripts/fetch $(urls)
	@printf "\n"

extract: fetch
	@printf "extracting downloaded files...\n"
	@sh -e scripts/extract $(urls)
	@printf "\n"

build/.built-%: toolchain
	@printf "building %s...\n" "$*"
	mkdir -p "$(BUILD)/$*"
	DESTDIR="$(BUILD)/$*" BUILD="$(BUILD)/root" J="$(JOBS)" sh -e scripts/build/$*
	cp -R "$(BUILD)/$*"/* "$(BUILD)/root"
	@touch build/.built-$*
	@printf "\n"

clean-%:
	@printf "cleaning archives/%s...\n" "$*"
	rm -rf archives/"$*"*

$(BUILD)/initramfs.cpio.gz:
	cd "$(BUILD)/root" && find . -print0 | cpio --null -ov --format=newc | gzip -9 > "$(BUILD)"/initramfs.cpio.gz

pack: $(BUILD)/initramfs.cpio.gz

repack:
	rm -f $(BUILD)/initramfs.cpio.gz
	$(MAKE) pack

build: prepare fetch extract $(foreach m,$(make),build/.built-$(m)) pack

clean:
	rm -rf downloads archives $(BUILD) toolchain

.PHONY:	clean all prepare fetch extract build pack

