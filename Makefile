export TARGET = iphone:clang:13.0:10.0
export ARCHS = armv7 arm64

DEBUG = 1
FINALPACKAGE = 1
GO_EASY_ON_ME = 0
LEAN_AND_MEAN = 1
THEOS_PACKAGE_DIR = Releases
INSTALL_TARGET_PROCESSES = TweakSettings
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)

include $(THEOS)/makefiles/common.mk

XCODEPROJ_NAME = TweakSettings
TweakSettings_XCODEFLAGS = PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"'
TweakSettings_CODESIGN_FLAGS = -SResources/entitlements.plist

include $(THEOS_MAKE_PATH)/xcodeproj.mk

SUBPROJECTS += TweakSettings-Utility

include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	$(ECHO_NOTHING)rm -f $(THEOS_STAGING_DIR)/Applications/TweakSettings.app/Localizable.strings$(ECHO_END)

after-install::
	install.exec "killall -9 TweakSettings; uicache -p /Applications/TweakSettings.app; uiopen tweaks:"
