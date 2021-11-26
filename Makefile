export TARGET = iphone:clang:14.4:10.0
export ARCHS = armv7 arm64

DEBUG = 1
DEBUG_EXT =
FINALPACKAGE = 1
GO_EASY_ON_ME = 0
LEAN_AND_MEAN = 1
THEOS_PACKAGE_DIR = Releases
INSTALL_TARGET_PROCESSES = TweakSettings
PACKAGE_VERSION = $(THEOS_PACKAGE_BASE_VERSION)$(DEBUG_EXT)

include $(THEOS)/makefiles/common.mk

LAUNCH_URL =
XCODEPROJ_NAME = TweakSettings
TweakSettings_XCODEFLAGS = PACKAGE_VERSION='@\"$(THEOS_PACKAGE_BASE_VERSION)\"'
TweakSettings_CODESIGN_FLAGS = -SResources/entitlements.plist

include $(THEOS_MAKE_PATH)/xcodeproj.mk

SUBPROJECTS += TweakSettings-Utility

include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	$(ECHO_NOTHING)rm -f $(THEOS_STAGING_DIR)/Applications/TweakSettings.app/Localizable.strings$(ECHO_END)
	$(ECHO_NOTHING)/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${THEOS_PACKAGE_BASE_VERSION}" "${THEOS_STAGING_DIR}/Applications/${XCODEPROJ_NAME}.app/Info.plist"$(ECHO_END)
	$(ECHO_NOTHING)/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${PACKAGE_VERSION}" "${THEOS_STAGING_DIR}/Applications/${XCODEPROJ_NAME}.app/Info.plist"$(ECHO_END)
	@echo "Set bundle version to: ${PACKAGE_VERSION}"

after-install::
	install.exec "killall -9 ${XCODEPROJ_NAME}; uicache -p /Applications/${XCODEPROJ_NAME}.app; uiopen tweaks:$(LAUNCH_URL)"