include $(TOPDIR)/rules.mk

PKG_NAME:=yaffmap_uci
PKG_RELEASE:=$(shell LC_ALL=C git show --format=%ai --name-only | LC_ALL=C git show --format=%ai --name-only \
	| head -n1 | sed -e 's/-/_/g' -e 's/:/_/g' -e 's/ /_/g' -e 's/+//g')
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/yaffmap_uci
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=Freifunk
  TITLE:=Freifunk Map Addon
  DEPENDS:=
endef

define Package/yaffmap_luci
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=Freifunk
  TITLE:=Freifunk Map Addon UI
  DEPENDS:=
endef

define Package/yaffmap_uci/description
  Yaffmap
endef

define Package/yaffmap_luci/description
  Yaffmap LUCI UI
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)/files
	mkdir -p $(PKG_BUILD_DIR)/luasrc
	cp -a ../files/* $(PKG_BUILD_DIR)/files
	cp -a ../luasrc/* $(PKG_BUILD_DIR)/luasrc
endef

define Build/Configure
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/luasrc
endef

define Package/yaffmap_uci/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/init.d/yaffmap $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/lib/yaffmap
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/lib/yaffmap/release.txt $(1)/lib/yaffmap/release.txt
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/common_json_helper $(1)/lib/yaffmap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/common_rp_olsr $(1)/lib/yaffmap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/uci_common $(1)/lib/yaffmap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/uci_rp_olsr $(1)/lib/yaffmap
endef

define Package/yaffmap_luci/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model
	$(CP) $(PKG_BUILD_DIR)/luasrc/controller/* $(1)/usr/lib/lua/luci/controller
	$(CP) $(PKG_BUILD_DIR)/luasrc/model/* $(1)/usr/lib/lua/luci/model
endef

$(eval $(call BuildPackage,yaffmap_uci))
$(eval $(call BuildPackage,yaffmap_luci))
