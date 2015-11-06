@interface BDSettingsManager : NSObject

@property (nonatomic, copy) NSDictionary *settings;

@property (nonatomic, readonly, getter=enabled) BOOL enabled;

+ (instancetype)sharedManager;
- (void)updateSettings;

@end
