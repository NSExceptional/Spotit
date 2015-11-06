#include "BDSRootListController.h"

#define SPOTIT_ORANGE [UIColor colorWithRed:0.918 green:0.569 blue:0.275 alpha:1] /*#ea9146*/

UIColor *originalTint;
UIWindow *settingsView;

@implementation BDSRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
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

- (void)openSupportMail {
    MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
    [mailer setSubject:@"Tweak Support - Spotit"];
    [mailer setToRecipients:[NSArray arrayWithObjects:@"bryce@brycedev.com", nil]];
    [self.navigationController presentViewController:mailer animated:YES completion: nil];
    mailer.mailComposeDelegate = self;
    [mailer release];
}

- (void)openTwitter:(NSString *)user {
	if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:user]]];
    else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitterrific:///profile?screen_name=" stringByAppendingString:user]]];
    else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetings:///user?screen_name=" stringByAppendingString:user]]];
    else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:user]]];
    else
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:user]]];
}

- (void)tannerTwitter {
    [self openTwitter: @"ThePantsThief"];
}

- (void)bryceTwitter {
    [self openTwitter: @"thebryc3isright"];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated: YES completion: nil];
}

@end
