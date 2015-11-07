include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Spotit+
Spotit+_FILES = BDSHeaderCell.m BDSClientController.m BDSFeedController.m BDSRootListController.m
Spotit+_INSTALL_PATH = /Library/PreferenceBundles
Spotit+_FRAMEWORKS = MessageUI UIKit
Spotit+_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Spotit+.plist$(ECHO_END)
