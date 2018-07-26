//
//  TBSettingsManager.m
//  Spotit
//
//  Created by Tanner on 11/3/16. Originally by Bryce Jackson.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "TBSettingsManager.h"

const char * bundleID = "com.pantsthief.spotit+";


NSString * SPStringFromClientType(SPClientType client) {
    switch (client) {
        case SPClientTypeSafari:
            return @"Safari";
        case SPClientTypeAlienBlue:
            return @"Alien Blue";
        case SPClientTypeLuna:
            return @"Luna";
        case SPClientTypeAMRC:
            return @"AMRC";
    }
}

NSString * SPStringFromFeedSourceType(SPFeedSourceType type) {
    switch (type) {
        case SPFeedSourceTypeAll:
            return @"All";
        case SPFeedSourceTypeFrontPage:
            return @"Front page";
        case SPFeedSourceTypeSubreddit:
            return @"Subreddit";
    }
}

NSString * SPStringFromFeedSortCriteria(SPFeedSortCriteria sort) {
    switch (sort) {
        case SPFeedSortCriteriaHot:
            return @"hot";
        case SPFeedSortCriteriaTopOfDay:
            return @"top of today";
        case SPFeedSortCriteriaNew:
            return @"new";
        case SPFeedSortCriteriaControversial:
            return @"controversial";
    }
}

void prefschanged(CFNotificationCenterRef c, void *observer, CFStringRef name, const void *o, CFDictionaryRef ui) {
    [[SettingsManager sharedManager] updateSettings];
}


@implementation TBSettingsManager

+ (instancetype)sharedManager {
    static dispatch_once_t p = 0;
    __strong static id _sharedSelf = nil;
    dispatch_once(&p, ^{
        _sharedSelf = [[self alloc] init];
    });
    return _sharedSelf;
}

- (id)init {
    self = [super init];
    if (self) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefschanged,
                                        CFSTR("com.brycedev.spotit+.prefschanged"), NULL,
                                        CFNotificationSuspensionBehaviorCoalesce);
        [self updateSettings];
    }
    return self;
}

- (void)updateSettings {
    self.settings = nil;
    CFStringRef appID = CFSTR(bundleID);
    CFPreferencesAppSynchronize(appID);
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID , kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    keyList = keyList ?: CFArrayCreate(NULL, NULL, 0, NULL);
    self.settings = (NSDictionary *)CFPreferencesCopyMultiple(keyList, appID , kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFRelease(keyList);
}

- (BOOL)shouldEnable {
    return self.enabled && [[NSProcessInfo processInfo] operatingSystemVersion].majorVersion == 9;
}

- (BOOL)enabled {
    return self.settings[@"enabled"] ? [self.settings[@"enabled"] boolValue] : YES;
}

- (SPClientType)clientType {
    return [self.settings[@"preferredClient"] integerValue];
}

- (SPFeedSourceType)feedSourceType {
    return [self.settings[@"source"] integerValue];
}

- (SPFeedSortCriteria)sortCriteria {
    return [self.settings[@"sort"] integerValue];
}

- (NSString *)preferredClient {
    return SPStringFromClientType(self.clientType);
}

- (NSString *)source {
    // was Personal
    return SPStringFromFeedSourceType(self.feedSourceType);
}

- (NSString *)subreddit {
    return self.settings[@"subreddit"] ?: @"jailbreak";
}

- (NSString *)sort {
    // was top
    return SPStringFromFeedSortCriteria(self.sortCriteria);
}

- (NSString *)redditUsername {
    return self.settings[@"redditUsername"] ?: @"";
}

- (NSString *)redditPassword {
    return self.settings[@"redditPassword"] ?: @"";
}

- (NSInteger)count {
    return self.settings[@"count"] ? [self.settings[@"count"] integerValue] : 20;
}

@end
