# busted_time
#
# Definitions in this section can be overriden on the command line or in the
# environment.
#

# PLAT: linux macosx win32 mingw
# platform to build for
PLAT?=linux

# LUA_VERSION: 5.1 5.2 5.3
# lua version to build against
LUA_VERSION?=5.1

# MYCFLAGS: to be set by user if needed
MYCFLAGS=

# MYLDFLAGS: to be set by user if needed
MYLDFLAGS=

# where lua headers are found for macosx builds
# LUAINC_macosx:
# /opt/local/include
LUAINC_macosx_base?=/opt/local/include
LUAINC_macosx?=$(LUAINC_macosx_base)/lua/$(LUA_VERSION)
# FIXME default should this default to fink or to macports?
# What happens when more than one Lua version is installed?
LUAPREFIX_macosx?=/opt/local
CDIR_macosx?=lib/lua/$(LUA_VERSION)
LDIR_macosx?=share/lua/$(LUA_VERSION)

# LUAINC_linux:
# /usr/include/lua$(LUA_VERSION)
# /usr/local/include
# /usr/local/include/lua$(LUA_VERSION)
# where lua headers are found for linux builds
LUAINC_linux_base?=/usr/include
LUAINC_linux?=$(LUAINC_linux_base)/lua/$(LUA_VERSION)
LUAPREFIX_linux?=/usr/local
CDIR_linux?=lib/lua/$(LUA_VERSION)
LDIR_linux?=share/lua/$(LUA_VERSION)

# LUAINC_freebsd:
# /usr/local/include/lua$(LUA_VERSION)
# where lua headers are found for linux builds
LUAINC_freebsd_base?=/usr/local/include/
LUAINC_freebsd?=$(LUAINC_freebsd_base)/lua$(LUA_VERSION)
LUAPREFIX_freebsd?=/usr/local/
CDIR_freebsd?=lib/lua/$(LUA_VERSION)
LDIR_freebsd?=share/lua/$(LUA_VERSION)

# where lua headers are found for mingw builds
# LUAINC_mingw:
# /opt/local/include
LUAINC_mingw_base?=/usr/include
LUAINC_mingw?=$(LUAINC_mingw_base)/lua/$(LUA_VERSION)
LUALIB_mingw_base?=/usr/bin
LUALIB_mingw?=$(LUALIB_mingw_base)/lua/$(LUA_VERSION)/lua$(subst .,,$(LUA_VERSION)).dll
LUAPREFIX_mingw?=/usr
CDIR_mingw?=lua/$(LUA_VERSION)
LDIR_mingw?=lua/$(LUA_VERSION)/lua


# LUAINC_win32:
# LUALIB_win32:
# where lua headers and libraries are found for win32 builds
LUAPREFIX_win32?=
LUAINC_win32?=$(LUAPREFIX_win32)/include/lua/$(LUA_VERSION)
PLATFORM_win32?=Release
CDIR_win32?=bin/lua/$(LUA_VERSION)/$(PLATFORM_win32)
LDIR_win32?=bin/lua/$(LUA_VERSION)/$(PLATFORM_win32)/lua
LUALIB_win32?=$(LUAPREFIX_win32)/lib/lua/$(LUA_VERSION)/$(PLATFORM_win32)
LUALIBNAME_win32?=lua$(subst .,,$(LUA_VERSION)).lib 


# prefix: /usr/local /usr /opt/local /sw
# the top of the default install tree
prefix?=$(LUAPREFIX_$(PLAT))

CDIR?=$(CDIR_$(PLAT))
LDIR?=$(LDIR_$(PLAT))

# DESTDIR: (no default)
# used by package managers to install into a temporary destination
DESTDIR=

#------
# Definitions below can be overridden on the make command line, but
# shouldn't have to be.


#------
# Install directories
#

INSTALL_DIR=install -d
INSTALL_DATA=install -m644
INSTALL_EXEC=install
INSTALL_TOP=$(DESTDIR)$(prefix)

INSTALL_TOP_LDIR=$(INSTALL_TOP)/$(LDIR)
INSTALL_TOP_CDIR=$(INSTALL_TOP)/$(CDIR)

INSTALL_LDIR=$(INSTALL_TOP_LDIR)/busted
INSTALL_CDIR=$(INSTALL_TOP_CDIR)/busted

#------
# Supported platforms
#
PLATS= macosx linux win32 mingw

#------
# Compiler and linker settings
# for Mac OS X
SO_macosx=so
O_macosx=o
CC_macosx=gcc
DEF_macosx=
CFLAGS_macosx= -I$(LUAINC) $(DEF) -Wall -O2 -fno-common \
	-fvisibility=hidden
LDFLAGS_macosx= -bundle -undefined dynamic_lookup -o
LD_macosx= export MACOSX_DEPLOYMENT_TARGET="10.3"; gcc

#------
# Compiler and linker settings
# for Linux
SO_linux=so
O_linux=o
CC_linux=gcc
DEF_linux=
CFLAGS_linux= -I$(LUAINC) $(DEF) -Wall -Wshadow -Wextra \
	-Wimplicit -O2 -ggdb3 -fpic -fvisibility=hidden
LDFLAGS_linux=-O -shared -fpic -o
LD_linux=gcc

#------
# Compiler and linker settings
# for FreeBSD
SO_freebsd=so
O_freebsd=o
CC_freebsd=gcc
DEF_freebsd=
CFLAGS_freebsd= -I$(LUAINC) $(DEF) -Wall -Wshadow -Wextra \
	-Wimplicit -O2 -ggdb3 -fpic -fvisibility=hidden
LDFLAGS_freebsd=-O -shared -fpic -o
LD_freebsd=gcc

#------
# Compiler and linker settings
# for MingW
SO_mingw=dll
O_mingw=o
CC_mingw=gcc
DEF_mingw=-DWINVER=0x0501
CFLAGS_mingw= -I$(LUAINC) $(DEF) -Wall -O2 -fno-common \
	-fvisibility=hidden
LDFLAGS_mingw= $(LUALIB) -shared -Wl,-s -o
LD_mingw=gcc


#------
# Compiler and linker settings
# for Win32
SO_win32=dll
O_win32=obj
CC_win32=cl
DEF_win32= //D "WIN32" //D "NDEBUG" //D "_WINDOWS" //D "_USRDLL" \
     //D "_CRT_SECURE_NO_WARNINGS" //D "_WINDLL"
CFLAGS_win32=//I "$(LUAINC)" $(DEF) //O2 //Ot //MD //W3 //nologo
LDFLAGS_win32= //nologo //link //NOLOGO //DLL //INCREMENTAL:NO \
    //MANIFEST //MANIFESTFILE:"intermediate.manifest" \
    //MANIFESTUAC:"level='asInvoker' uiAccess='false'" \
	//SUBSYSTEM:WINDOWS //OPT:REF //OPT:ICF //DYNAMICBASE:NO \
    //MACHINE:X86 /LIBPATH:"$(shell cmd //c echo $(LUALIB))" \
	$(LUALIBNAME_win32) //OUT:
LD_win32=cl

.SUFFIXES: .obj

.c.obj:
	$(CC) $(CFLAGS) //Fo"$@" //c $<

#------
# Output file names
#
SO=$(SO_$(PLAT))
O=$(O_$(PLAT))
SOLIB=ccore.$(SO)

#------
# Settings selected for platform
#
CC=$(CC_$(PLAT))
DEF=$(DEF_$(PLAT))
CFLAGS=$(MYCFLAGS) $(CFLAGS_$(PLAT))
LDFLAGS=$(MYLDFLAGS) $(LDFLAGS_$(PLAT))
LD=$(LD_$(PLAT))
LUAINC= $(LUAINC_$(PLAT))
LUALIB= $(LUALIB_$(PLAT))

#------
# Objects
#
OBJS=ccore.$(O) compat.$(O) time.$(O)

#------
# Targets
#
default: $(PLAT)

freebsd:
	$(MAKE) all PLAT=freebsd

macosx:
	$(MAKE) all PLAT=macosx

win32:
	$(MAKE) all PLAT=win32

linux:
	$(MAKE) all PLAT=linux

mingw:
	$(MAKE) all PLAT=mingw

none:
	@echo "Please run"
	@echo "   make PLATFORM"
	@echo "where PLATFORM is one of these:"
	@echo "   $(PLATS)"

all: $(SOLIB)

$(SOLIB): $(OBJS)
	$(LD) $(OBJS) $(LDFLAGS)$@

install: all
	$(INSTALL_DIR) $(INSTALL_TOP_LDIR)
	$(INSTALL_DIR) $(INSTALL_CDIR)
	$(INSTALL_EXEC) $(SOLIB) $(INSTALL_CDIR)/$(SOLIB)

local:
	$(MAKE) install INSTALL_TOP_CDIR=.. INSTALL_TOP_LDIR=..

clean:
	rm -f $(SOLIB) $(OBJS) ../busted/$(SOLIB)

print:
	@echo PLAT=$(PLAT)
	@echo LUA_VERSION=$(LUA_VERSION)
	@echo prefix=$(prefix)
	@echo LUAINC_$(PLAT)=$(LUAINC_$(PLAT))
	@echo LUALIB_$(PLAT)=$(LUALIB_$(PLAT))
	@echo INSTALL_TOP_CDIR=$(INSTALL_TOP_CDIR)
	@echo INSTALL_TOP_LDIR=$(INSTALL_TOP_LDIR)

.PHONY: all $(PLATS) default clean none
