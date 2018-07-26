//
//  SPUISearchViewController.m
//  Spotit
//
//  Created by Tanner on 11/3/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#define NSFormatString(...) [NSString stringWithFormat:__VA_ARGS__]
#define URL(string) [NSURL URLWithString:string]
#define UIApplicationCanOpenURL(string) [[UIApplication sharedApplication] canOpenURL:URL(string)]
#define UIApplicationOpenURL(string) [[UIApplication sharedApplication] openURL:URL(string)]


%hook SPUISearchViewController

// Force touch
- (void)viewDidLoad {
    %orig;
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        [self registerForPreviewingWithDelegate:self sourceView:[self searchTableView]];
    }
}

- (NSArray *)resultsForRow:(NSInteger)row inSection:(NSInteger)section {
    if (section == 2 || self.shouldShowFeedSection) {
        return @[self.links[row]];
        
    }
    
    //if (row == 0) return %orig(row, section);
    return %orig(row, section);
}

- (NSInteger)numberOfSectionsInTableView:(id)tv {
    // Hide links on spotlight pull down
    // TODO find a way
    if (![self _isPullDownSpotlight]) {
        return self.links.count ? 3 : 2;
    }
        
    return %orig(tv);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 2 && self.shouldShowFeedSection) {
        return self.links.count;
    }
    
    return %orig(tableView, section);
}

- (void)tableView:(id)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.section == 2 && self.shouldShowFeedSection) {
        TBLink *post = self.links[ip.row];
        NSString *defaultURL = NSFormatString(@"https://redd.it/%@", post.identifier);
        SPClientType client  = [BDSettingsManager sharedManager].clientType;
        
        switch (client) {
            case SPClientTypeSafari: {
                UIApplicationOpenURL(defaultURL);
                break;
            }
            case SPClientTypeAlienBlue: {
                if (UIApplicationCanOpenURL(@"alienblue://example")) {
                    UIApplicationOpenURL(NSFormatString@"alienblue://thread/%@", post.url));
                }
                break;
            }
            case SPClientTypeLuna: {
                if (UIApplicationCanOpenURL(@"luna://example")) {
                    UIApplicationOpenURL(NSFormatString@"luna://post/%@", post.identifier));
                }
                break;
            }
            case SPClientTypeAMRC: {
                if (UIApplicationCanOpenURL(@"amrc://example")) {
                    UIApplicationOpenURL(NSFormatString(@"amrc://redd.it/%@", post.identifier));
                }
                break;
            }
        }
        
        UIApplicationOpenURL(defaultURL);
    }
    else {
        %orig(tv, ip);
    }
}

- (SPUISearchTableHeaderView *)tableView:(id)tv viewForHeaderInSection:(int)section {
    if (section == 2 && self.shouldShowFeedSection) {
        SPUISearchTableHeaderView *v = %orig(tv, section);
        [v updateWithTitle:@"Reddit" section:section isExpanded:YES];
        return v;
    }
    
    return %orig(tv, section);
}

%end
    