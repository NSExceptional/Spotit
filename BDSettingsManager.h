@interface BDSettingsManager : NSObject

@property (nonatomic, copy) NSDictionary *settings;

@property (nonatomic, readonly) BOOL enabled;
@property (nonatomic, readonly) NSString * preferredClient;
@property (nonatomic, readonly) NSString * subreddit;
@property (nonatomic, readonly) NSString *sort;
@property (nonatomic, readonly) NSString *source;
@property (nonatomic, readonly) NSInteger count;

+ (instancetype)sharedManager;
- (void)updateSettings;

@end
