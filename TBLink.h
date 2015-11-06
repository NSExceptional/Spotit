@class SPSearchResult;

@interface TBLink : NSObject

+ (instancetype)linkWithJSON:(NSDictionary *)json;

@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *author;
@property (nonatomic, readonly, copy) NSString *domain;
@property (nonatomic, readonly, copy) NSString *url;
@property (nonatomic, readonly, copy) NSString *subreddit;
@property (nonatomic, readonly, copy) NSString *body;
@property (nonatomic, readonly, copy) NSURL *permalink;
@property (nonatomic, readonly, copy) NSNumber *score;
@property (nonatomic, readonly, copy) NSNumber *comments;
@property (nonatomic, readonly, copy) NSString *age;
@property (nonatomic, readonly, copy) NSURL *thumbnailURL;
@property (nonatomic, readonly, copy) NSString *identifier;

@property (nonatomic, assign) SPSearchResult *result;
@property (nonatomic, assign) UIImage *image;

@end
