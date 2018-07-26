//
//  SBSearchViewController.m
//  Spotit
//
//  Created by Tanner on 11/3/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

%hook SBSearchViewController

- (void)didFinishPresenting:(BOOL)p {
    %orig(p);
    
    // TODO this only loads stuff once
    if (p) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([TBSettingsManager sharedManager].feedSourceType == SPFeedSourceTypeFrontPage) {
                    [[self valueForKey:@"_searchViewController"] loadRedditDataAuth];
                } else {
                    [[self valueForKey:@"_searchViewController"] loadRedditDataJson];
                }
            });
        });
    }
}

%end