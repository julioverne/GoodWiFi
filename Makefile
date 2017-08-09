include theos/makefiles/common.mk

SUBPROJECTS += goodwifihook
SUBPROJECTS += goodwifisettings

include $(THEOS_MAKE_PATH)/aggregate.mk

all::
	
