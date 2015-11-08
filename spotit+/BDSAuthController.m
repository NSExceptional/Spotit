#import "Global.h"
#include "BDSAuthController.h"

UIColor *originalTint;
UIWindow *settingsView;

@implementation BDSAuthController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Auth" target:self] retain];
	}
	return _specifiers;
}

- (void)loadView {
	[super loadView];
	[UISwitch appearanceWhenContainedIn: self.class, nil].onTintColor = SPOTIT_ORANGE;
	[UISegmentedControl appearanceWhenContainedIn: self.class, nil].tintColor = SPOTIT_ORANGE;
}

- (void)viewWillAppear:(BOOL)animated {
	settingsView = [[UIApplication sharedApplication] keyWindow];
	originalTint = settingsView.tintColor;
	settingsView.tintColor = SPOTIT_ORANGE;
}

- (void)viewWillDisappear:(BOOL)animated {
	settingsView.tintColor = originalTint;
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [[self view] endEditing:YES];
}

@end
