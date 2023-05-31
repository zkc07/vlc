# libogg

OGG_VERSION := 1.3.5

OGG_URL := $(XIPH)/ogg/libogg-$(OGG_VERSION).tar.xz
#OGG_CVSROOT := :pserver:anoncvs@xiph.org:/usr/local/cvsroot

PKGS += ogg
ifeq ($(call need_pkg,"ogg >= 1.0"),)
PKGS_FOUND += ogg
endif

$(TARBALLS)/libogg-$(OGG_VERSION).tar.xz:
	$(call download_pkg,$(OGG_URL),ogg)

.sum-ogg: libogg-$(OGG_VERSION).tar.xz

libogg: libogg-$(OGG_VERSION).tar.xz .sum-ogg
	$(UNPACK)
	$(MOVE)

OGG_CONF := -DINSTALL_DOCS:BOOL=OFF

.ogg: libogg toolchain.cmake
	$(CMAKECLEAN)
	$(HOSTVARS) $(CMAKE) $(OGG_CONF)
	+$(CMAKEBUILD)
	$(CMAKEINSTALL)
	touch $@
