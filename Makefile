export THEOS_PACKAGE_SCHEME = roothide
TARGET := iphone:clang:14.5:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MotionSpoofer
MotionSpoofer_FILES = Tweak.x
MotionSpoofer_FRAMEWORKS = UIKit CoreMotion Foundation
MotionSpoofer_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
