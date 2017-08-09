include theos/makefiles/common.mk

TWEAK_NAME = GoodWiFi

GoodWiFi_FILES = /mnt/d/codes/goodwifi/goodwifihook/GoodWiFi.xm
GoodWiFi_FRAMEWORKS = CydiaSubstrate UIKit Security
GoodWiFi_LDFLAGS = -Wl,-segalign,4000

export ARCHS = armv7 arm64
GoodWiFi_ARCHS = armv7 arm64

include $(THEOS_MAKE_PATH)/tweak.mk
	
all::
	