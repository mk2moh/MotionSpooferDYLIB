export THEOS_PACKAGE_SCHEME = roothide
TARGET := iphone:clang:14.5:15.0
ARCHS = arm64 arm64e
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MotionSpooferTrollFools
MotionSpooferTrollFools_FILES = Tweak.x
MotionSpooferTrollFools_FRAMEWORKS = UIKit CoreMotion CoreLocation Foundation
MotionSpooferTrollFools_LOGOS_DEFAULT_GENERATOR = internal
MotionSpooferTrollFools_CFLAGS = -fobjc-arc -DMS_TROLLFOOLS_BUILD=1 -Wno-deprecated-declarations -Wno-unused-but-set-variable -Wno-unused-variable -Wno-unused-function
MotionSpooferTrollFools_INSTALL = 0

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
