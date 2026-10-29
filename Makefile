export THEOS_PACKAGE_SCHEME = roothide
TARGET := iphone:clang:14.5:15.0
ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = MotionSpoofer
MotionSpoofer_FILES = Tweak.x
MotionSpoofer_FRAMEWORKS = UIKit CoreMotion CoreLocation HealthKit Foundation
MotionSpoofer_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error=deprecated-declarations -Wno-unused-but-set-variable -Wno-unused-variable -Wno-unused-function
include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = MotionSpooferPrefs
MotionSpooferPrefs_FILES = prefs/MSRootListController.m
MotionSpooferPrefs_FRAMEWORKS = UIKit Foundation MobileCoreServices
MotionSpooferPrefs_PRIVATE_FRAMEWORKS = Preferences
MotionSpooferPrefs_RESOURCE_DIRS = prefs/Resources
MotionSpooferPrefs_INSTALL_PATH = /Library/PreferenceBundles
MotionSpooferPrefs_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences"$(ECHO_END)
	$(ECHO_NOTHING)cp prefs/MotionSpooferPrefs.plist "$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/MotionSpooferPrefs.plist"$(ECHO_END)

include $(THEOS_MAKE_PATH)/aggregate.mk
