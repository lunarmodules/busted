# busted_time makefile
#
# see csrc/makefile for description of how to customize the build
#
# Targets:
#   install            install system independent support
#   install-all        install for lua51 lua52 lua53
#   print              print the build settings

PLAT?= linux
PLATS= macosx linux win32 mingw freebsd

all: $(PLAT)

$(PLATS) none install local clean:
	$(MAKE) -C csrc $@

print:
	$(MAKE) -C csrc $@

test:
	@bin/busted

install-all:
	$(MAKE) clean
	@cd csrc && $(MAKE) $(PLAT) LUA_VERSION=5.1
	@cd csrc && $(MAKE) install LUA_VERSION=5.1
	$(MAKE) clean
	@cd csrc && $(MAKE) $(PLAT) LUA_VERSION=5.2
	@cd csrc && $(MAKE) install LUA_VERSION=5.2
	$(MAKE) clean
	@cd csrc && $(MAKE) $(PLAT) LUA_VERSION=5.3
	@cd csrc && $(MAKE) install LUA_VERSION=5.3

.PHONY: test
