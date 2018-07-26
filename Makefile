include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spotit+
Spotit+_FILES = TBSettingsManager.m TBLink.m Tweak.xm
Spotit+_FRAMEWORKS = CFNetwork Foundation UIKit
Spotit+_PRIVATE_FRAMEWORKS = Search SpotlightUI

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += spotit+
include $(THEOS_MAKE_PATH)/aggregate.mk
