#import "BDSettingsManager.h"

@implementation BDSettingsManager

+ (instancetype)sharedManager {
    static dispatch_once_t p = 0;
    __strong static id _sharedSelf = nil;
    dispatch_once(&p, ^{
        _sharedSelf = [[self alloc] init];
    });
    return _sharedSelf;
}

void prefschanged(CFNotificationCenterRef center, void * observer, CFStringRef name, const void * object, CFDictionaryRef userInfo) {
    [[BDSettingsManager sharedManager] updateSettings];
}

- (id)init {
    if (self = [super init]) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefschanged, CFSTR("com.brycedev.spotit+.prefschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        [self updateSettings];
        //HBLogInfo(@"the settings for Spotit+ are : %@", [self settings]);
    }
    return self;
}

- (void)updateSettings {
    self.settings = nil;
    CFPreferencesAppSynchronize(CFSTR("com.brycedev.spotit+"));
    CFStringRef appID = CFSTR("com.brycedev.spotit+");
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID , kCFPreferencesCurrentUser, kCFPreferencesAnyHost) ?: CFArrayCreate(NULL, NULL, 0, NULL);
    self.settings = (NSDictionary *)CFPreferencesCopyMultiple(keyList, appID , kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFRelease(keyList);
}

- (BOOL)enabled {
    return self.settings[@"enabled"] ? [self.settings[@"enabled"] boolValue] : YES;
}

- (NSString *)preferredClient {
    NSInteger val = self.settings[@"preferredClient"] ? [self.settings[@"preferredClient"] integerValue] : 0;
    if(val == 0){
        return @"Safari";
    }else if(val == 1){
        return @"Alien Blue";
    }else if(val == 2){
        return @"Luna";
    }else if(val == 3){
        return @"AMRC";
    }
    return @"Safari";
}

- (NSString *)source {
    NSInteger val = self.settings[@"source"] ? [self.settings[@"source"] integerValue] : 0;
    if(val == 0){
        return @"All";
    }else if(val == 1){
        return @"Personal";
    }else if(val == 2){
        return @"Subreddit";
    }
    return @"All";
}

- (NSString *)subreddit {
    return self.settings[@"subreddit"] ? self.settings[@"subreddit"] : @"jailbreak";
}

- (NSString *)sort {
    NSInteger val = self.settings[@"sort"] ? [self.settings[@"sort"] integerValue] : 0;
    if(val == 0){
        return @"hot";
    }else if(val == 1){
        return @"top";
    }else if(val == 2){
        return @"new";
    }
    return @"hot";
}

- (NSInteger)count {
    return self.settings[@"count"] ? [self.settings[@"count"] integerValue] : 20;
}

@end
