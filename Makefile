include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Spotit+
Spotit+_FILES = BDSettingsManager.m TBLink.m Tweak.xm
Spotit+_FRAMEWORKS = Foundation UIKit
Spotit+_PRIVATE_FRAMEWORKS = Search SpotlightUI

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += spotit+
include $(THEOS_MAKE_PATH)/aggregate.mk
