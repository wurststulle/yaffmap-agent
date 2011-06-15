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
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/yaffmap_uci/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,yaffmap_uci))