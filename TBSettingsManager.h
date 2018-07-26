//
//  TBSettingsManager.h
//  Spotit
//
//  Created by Tanner on 11/3/16. Originally by Bryce Jackson.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "Interfaces.h"


typedef NS_ENUM(NSUInteger, SPClientType) {
    SPClientTypeSafari,
    SPClientTypeAlienBlue,
    SPClientTypeLuna,
    SPClientTypeAMRC
};

typedef NS_ENUM(NSUInteger, SPFeedSourceType) {
    SPFeedSourceTypeAll,
    SPFeedSourceTypeFrontPage,
    SPFeedSourceTypeSubreddit
};

typedef NS_ENUM(NSUInteger, SPFeedSortCriteria) {
    SPFeedSortCriteriaHot,
    SPFeedSortCriteriaTopOfDay,
    SPFeedSortCriteriaNew,
    SPFeedSortCriteriaControversial
};


@interface TBSettingsManager : NSObject

@property (nonatomic, copy) NSDictionary *settings;

@property (nonatomic, readonly) BOOL      shouldEnable;
@property (nonatomic, readonly) BOOL      enabled;
@property (nonatomic, readonly) NSString  *preferredClient;
@property (nonatomic, readonly) NSString  *subreddit;
@property (nonatomic, readonly) NSString  *sort;
@property (nonatomic, readonly) NSString  *redditUsername;
@property (nonatomic, readonly) NSString  *redditPassword;
@property (nonatomic, readonly) NSString  *source;
@property (nonatomic, readonly) NSInteger count;

@property (nonatomic, readonly) SPClientType       clientType;
@property (nonatomic, readonly) SPFeedSourceType   feedSourceType;
@property (nonatomic, readonly) SPFeedSortCriteria sortCriteria;

@property (nonatomic) NSDate *APICallFailureDate;

+ (instancetype)sharedManager;
- (void)updateSettings;

@end
