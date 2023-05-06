include $(THEOS)/makefiles/common.mk

TOOL_NAME = tweaksettings-utility

tweaksettings-utility_FILES = main.c
tweaksettings-utility_CFLAGS = -fobjc-arc
TARGET_CODESIGN_FLAGS = "-Sentitlements.plist"

include $(THEOS_MAKE_PATH)/tool.mk

before-package::
	chmod +s $(THEOS_STAGING_DIR)/usr/bin/tweaksettings-utility