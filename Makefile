VERSION			=scm

CFLAGS			?= -Os
CXXFLAGS		?= $(CFLAGS)

CFLAGS			+= -I$(BUILD)/include -L$(BUILD)/lib -static
LDFLAGS			+= -static

export CFLAGS
export CXXFLAGS
export LDFLAGS

JOBS			= $$(grep -c processor /proc/cpuinfo)

BUILD			?= $(PWD)/build

PATH			+= :$(PWD)/toolchain

urls            =	\
    http://www.musl-libc.org/releases/musl-1.0.5.tar.gz		\
    http://landley.net/toybox/downloads/toybox-0.7.0.tar.gz	\
	http://sources.voidlinux.eu/sources/mksh-R52b/mksh-R52b.tgz

make			= musl toybox mksh

all:
	@printf "lighter $(VERSION)\n\n"
	@printf "%-20s%-20s\n"	\
		"CFLAGS"		"$(CFLAGS)"		\
		"CXXFLAGS"		"$(CXXFLAGS)"	\
		"MAKEFLAGS"		"$(MAKEFLAGS)"	\
		"BUILD"			"$(BUILD)"
	@printf "\n"
	@$(MAKE) --no-print-directory build

toolchain:
	@printf "making any needed toolchain links...\n"
	@sh -e scripts/toolchain
	@printf "\n"
#	@for d in $(dirs);do echo "mkdir -p $(BUILD)/$$d"; [ -d "$$d" ] || mkdir -p $(BUILD)/"$$d";done

skel:
	@printf "copying skeleton root to %s...\n" "$(BUILD)"
	-mkdir -p "$(BUILD)"
	@cp -r skel/* $(BUILD)
	@printf "\n"

prepare: toolchain skel

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
	@BUILD="$(BUILD)" J="$(JOBS)" sh -e scripts/build/$* && touch build/.built-$*
	@printf "\n"

clean-%:
	@printf "cleaning archives/%s...\n" "$*"
	@rm -rf archives/"$*"*

build: prepare fetch extract $(foreach m,$(make),build/.built-$(m))

clean:
	rm -rf downloads archives $(BUILD) toolchain

.PHONY:	all skel toolchain fetch extract build

