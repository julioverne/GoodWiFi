TARGET = iphone:11.2:8.0

include $(THEOS)/makefiles/common.mk

SUBPROJECTS += goodwifihook
SUBPROJECTS += goodwifisettings

include $(THEOS_MAKE_PATH)/aggregate.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp GoodWiFiSettings.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/GoodWiFiSettings.plist$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)