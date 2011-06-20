include $(TOPDIR)/rules.mk

PKG_NAME:=yaffmap_uci
PKG_RELEASE:=0.1.1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/yaffmap_uci
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=Freifunk
  TITLE:=Freifunk Map Addon
  DEPENDS:=
endef

define Package/yaffmap_uci/description
  Yaffmap
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)/files
	cp -a ../files/* $(PKG_BUILD_DIR)/files
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/yaffmap_uci/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/etc/init.d/yaffmap $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/lib/yaffmap
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/files/lib/yaffmap/release.txt $(1)/lib/yaffmap/release.txt
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/common_json_helper $(1)/lib/yaffmap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/common_rp_olsr $(1)/lib/yaffmap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/fff_common $(1)/lib/yaffmap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/fff_rp_olsr $(1)/lib/yaffmap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/platform_common $(1)/lib/yaffmap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/platform_rp_olsr $(1)/lib/yaffmap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/uci_common $(1)/lib/yaffmap
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/files/lib/yaffmap/uci_rp_olsr $(1)/lib/yaffmap
endef

$(eval $(call BuildPackage,yaffmap_uci))