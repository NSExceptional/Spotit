@interface BDSettingsManager : NSObject

@property (nonatomic, copy) NSDictionary *settings;

@property (nonatomic, readonly) BOOL enabled;
@property (nonatomic, readonly) NSInteger preferredClient;

+ (instancetype)sharedManager;
- (void)updateSettings;

@end
