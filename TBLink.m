#import "TBLink.h"

@implementation TBLink

+ (instancetype)linkWithJSON:(NSDictionary *)json {
return [[self alloc] initWithJSON:json];
}

- (id)initWithJSON:(NSDictionary *)json {
    NSParameterAssert(json);
    self = [super init];
    if (self) {
        NSDictionary *data = json[@"data"];
        _title        = data[@"title"];
        _author       = data[@"author"];
        _domain       = data[@"domain"];
        _url          = data[@"url"];
        _subreddit    = data[@"subreddit"];
        _body         = data[@"selftext"] ?: @"";
        _permalink    = [NSURL URLWithString:[NSString stringWithFormat:@"https://redd.it/%@", data[@"id"]]];
        _score        = data[@"score"];
        _comments     = data[@"num_comments"];
        _age          = [self timeSinceNowFromDate:[NSDate dateWithTimeIntervalSince1970:[data[@"created_utc"] floatValue]]];
        _thumbnailURL = data[@"thumbnail"] ? [NSURL URLWithString:data[@"thumbnail"]] : nil;
        _identifier   = data[@"id"];
    }

    return self;
}

- (void)setImage:(id)image {
    if ([image size].width < 75.f) {
        _image = image;
        return;
    }

    CGFloat scale = 90.f/[image size].width;
    CGSize newSize = CGSizeMake([image size].width * scale, [image size].height * scale);
    UIGraphicsBeginImageContextWithOptions(newSize, YES, 0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];

    _image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (NSString *)timeSinceNowFromDate:(NSDate *)date {
    NSInteger age = -round(date.timeIntervalSinceNow)/60;
    NSString *text;

    // if it was less than a minute, make it 1
    if (age < 1) age = 1;
    // if more than 59 minutes, convert to hours
    if (age > 59)
    {
    age /= 60;
    // if more than 23 hours, convert to days
    if (age > 23)
    {
    age /= 24;
    // if more than 365 days, convert to years
    if (age > 364)
    {
    age /= 365;
    text = [NSString stringWithFormat:@"%liy", (long)age];
    }
    else
    text = [NSString stringWithFormat:@"%lid", (long)age];
    }
    else
    text = [NSString stringWithFormat:@"%lih", (long)age];
    }
    else
    text = [NSString stringWithFormat:@"%lim", (long)age];

    return text;
}

@end
