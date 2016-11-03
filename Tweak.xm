#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <CoreGraphics/CGAffineTransform.h>
#import "Interfaces.h"
#import "TBLink.h"
#import "BDSettingsManager.h"

BOOL searchIsActive;

//////////////////////////////////////////
%group iOS9
//////////////////////////////////////////
@implementation SPSearchResult (TB)

- (NSString *)body {
    return [self additionalPropertyDict][@"descriptions"][0][@"formatted_text"][0][@"text"];
}

- (void)setBody:(id)body {
    if ([self additionalPropertyDict][@"descriptions"][0][@"formatted_text"][0])
        [self additionalPropertyDict][@"descriptions"][0][@"formatted_text"][0][@"text"] = body;
    else {
        NSMutableDictionary *dict = [@{@"descriptions": @[@{@"formatted_text": @[[NSMutableDictionary new]]}]} mutableCopy];
        dict[@"descriptions"][0][@"formatted_text"][0][@"text"] = body;
        [self setValue:dict forKey:@"additionalPropertyDict"];
    }
}

- (void)setImage:(id)image {
    objc_setAssociatedObject(self, @selector(image), image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

%hook SPSearchResult

- (id)image {
    return %orig ?: objc_getAssociatedObject(self, @selector(image));
}

%end

@implementation SPUISearchViewController (TB)

- (NSArray *)links {
    return objc_getAssociatedObject(self, @selector(links));
}

- (void)setLinks:(NSArray *)links {
    objc_setAssociatedObject(self, @selector(links), links, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    CGPoint position = [[self searchTableView] convertPoint:location fromView:[self searchTableView]];
    NSIndexPath *ip = [[self searchTableView] indexPathForRowAtPoint:position];
    
    if (ip.section == 2 && !searchIsActive) {
        UITableViewCell *cell = [[self searchTableView] cellForRowAtIndexPath:ip];
        id sf = [[%c(SFSafariViewController) alloc] initWithURL:[NSURL URLWithString:(NSString *)[[self links][ip.row] contentURL]]];
        [previewingContext setSourceRect:[cell frame]];
        
        return sf;
    }
    
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self presentViewController:viewControllerToCommit animated:YES completion:nil];
}

- (void)loadRedditDataJson {
    NSString *source = [[BDSettingsManager sharedManager] source];
    NSString *url = [NSString stringWithFormat:@"https://www.reddit.com/hot.json?limit=%@", @(20)];
    
    if ([source isEqualToString:@"All"]) {
        url = [NSString stringWithFormat:@"https://www.reddit.com/r/all/%@.json?limit=%@", [[BDSettingsManager sharedManager] sort], @([[BDSettingsManager sharedManager] count])];
    } else if ([source isEqualToString:@"Subreddit"]) {
        url = [NSString stringWithFormat:@"https://www.reddit.com/r/%@/%@.json?limit=%@", [[BDSettingsManager sharedManager] subreddit], [[BDSettingsManager sharedManager] sort], @([[BDSettingsManager sharedManager] count])];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"GET";
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSError *jsonError = nil;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            
            if (!jsonError) {
                NSMutableArray *links = [NSMutableArray new];
                
                for (NSDictionary *linkjson in json[@"data"][@"children"]) {
                    TBLink *link = [TBLink linkWithJSON:linkjson];
                    SPSearchResult *result = [SPSearchResult new];
                    [result setTitle:link.title];
                    NSString *body = [link.body stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                    
                    if ([body length] > 160) {
                        [result setBody:[NSString stringWithFormat:@"%@...", [body substringToIndex:160]]];
                    } else {
                        [result setBody:body];
                    }
                    
                    [result setSubtitle:link.subreddit];
                    [result setFootnote:[NSString stringWithFormat:@"%@ – %@, %@", link.domain, link.score, link.age]];
                    [result setContentURL:link.url];
                    [result setUrl:link.identifier];
                    
                    [link setResult:result];
                    [links addObject:link];
                }
                
                __block NSInteger count = [links count];
                for (TBLink *link in links) {
                    if (![[link.thumbnailURL absoluteString] length]) {
                        if (--count == 0) {
                            [self setLinks:[links valueForKeyPath:@"@unionOfObjects.result"]];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[self searchTableView] reloadData];
                            });
                        }
                        continue;
                    }
                    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:link.thumbnailURL];
                    request.HTTPMethod = @"GET";
                    [[session dataTaskWithRequest:request completionHandler:^(NSData *data1, NSURLResponse *response1, NSError *error1) {
                        if (!error1 && data1.length) {
                            link.image = [UIImage imageWithData:data1];
                            [link.result setImage:link.image];
                        }
                        if (--count == 0) {
                            [self setLinks:[links valueForKeyPath:@"@unionOfObjects.result"]];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[self searchTableView] reloadData];
                            });
                        }
                    }] resume];
                }
            }
        }
    }] resume];
}
- (void)loadRedditDataAuth {
    NSURL *baseURL      = [NSURL URLWithString:@"https://ssl.reddit.com/"];
    NSString *username  = [[BDSettingsManager sharedManager] redditUsername];
    NSString *password  = [[BDSettingsManager sharedManager] redditPassword];
    NSString *urlString = [[NSURL URLWithString:[NSString stringWithFormat:@"api/login/%@?user=%@&passwd=%@&api_type=json", username, username, password] relativeToURL:baseURL] absoluteString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:YES];
    NSURLSession *mainSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[mainSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            NSError *jsonError = nil;
            NSDictionary *authJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            
            if (authJson[@"json"][@"errors"]) {
                for (NSString *error in authJson[@"json"][@"errors"]) {
                    if ([error containsString:@"wrong"]) {
                        HBLogInfo(@"user should check their credentials");
                        //maybe display a banner, similar to orangered
                        return;
                    }
                }
            }
            
            if (authJson[@"json"][@"data"] && authJson[@"json"][@"data"][@"modhash"] && authJson[@"json"][@"data"][@"cookie"]) {
                HBLogInfo(@"the user was logged in successfully");
                NSString *feedString = [NSString stringWithFormat:@"https://www.reddit.com/%@.json?limit=%@", [[BDSettingsManager sharedManager] sort], @([[BDSettingsManager sharedManager] count])];
                NSMutableURLRequest *meRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:feedString]];
                meRequest.HTTPMethod = @"GET";
                
                [[mainSession dataTaskWithRequest:meRequest completionHandler:^(NSData *data1, NSURLResponse *response1, NSError *error1) {
                    if (!error1 && data1.length) {
                        HBLogInfo(@"attempting to get the user's feed");
                        NSError *jsonError = nil;
                        NSDictionary *feedJson = [NSJSONSerialization JSONObjectWithData:data1 options:0 error:&jsonError];
                        
                        if (!jsonError) {
                            HBLogInfo(@"got the json : %@", feedJson);
                            NSMutableArray *links = [NSMutableArray new];
                            
                            for (NSDictionary *linkjson in feedJson[@"data"][@"children"]) {
                                TBLink *link = [TBLink linkWithJSON:linkjson];
                                SPSearchResult *result = [SPSearchResult new];
                                [result setTitle:link.title];
                                
                                NSString *body = [link.body stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
                                if ([body length] > 160) {
                                    [result setBody:[NSString stringWithFormat:@"%@...", [body substringToIndex:160]]];
                                } else {
                                    [result setBody:body];
                                }
                                
                                [result setSubtitle:link.subreddit];
                                [result setFootnote:[NSString stringWithFormat:@"%@ – %@, %@", link.domain, link.score, link.age]];
                                [result setContentURL:link.url];
                                [result setUrl:link.identifier];
                                [link setResult:result];
                                [links addObject:link];
                            }
                            __block NSInteger count = [links count];
                            for (TBLink *link in links) {
                                if (![[link.thumbnailURL absoluteString] length]) {
                                    if (--count == 0) {
                                        [self setLinks:[links valueForKeyPath:@"@unionOfObjects.result"]];
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [[self searchTableView] reloadData];
                                        });
                                    }
                                    continue;
                                }
                                NSMutableURLRequest *thumbnailRequest = [[NSMutableURLRequest alloc] initWithURL:link.thumbnailURL];
                                thumbnailRequest.HTTPMethod = @"GET";
                                [[mainSession dataTaskWithRequest:thumbnailRequest completionHandler:^(NSData *data2, NSURLResponse *response2, NSError *error2) {
                                    if (!error2 && data2.length) {
                                        link.image = [UIImage imageWithData:data2];
                                        [link.result setImage:link.image];
                                    }
                                    if (--count == 0) {
                                        [self setLinks:[links valueForKeyPath:@"@unionOfObjects.result"]];
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [[self searchTableView] reloadData];
                                        });
                                    }
                                }] resume];
                            }
                        }
                    }
                }] resume];
            }
        }
    }] resume];
}

@end

%hook SBSearchViewController

- (void)didFinishPresenting:(BOOL)p {
    %orig(p);
    if (p) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if ([[[BDSettingsManager sharedManager] source] isEqualToString:@"Personal"]) {
                    [[self valueForKey:@"_searchViewController"] loadRedditDataAuth];
                } else {
                    [[self valueForKey:@"_searchViewController"] loadRedditDataJson];
                }
            });
        });
    }
}

%end

%hook SPUISearchViewController

- (void)viewDidLoad {
    %orig;
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        [self registerForPreviewingWithDelegate:self sourceView:[self searchTableView]];
    }
}

- (NSArray *)resultsForRow:(NSInteger)row inSection:(NSInteger)section {
    if (section != 2 || searchIsActive) return %orig(row, section);
        //if (row == 0) return %orig(row, section);
        return @[[self links][row]];
}

- (NSInteger)numberOfSectionsInTableView:(id)tv {
    if (![self _isPullDownSpotlight])
        return [[self links] count] > 0 ? 3 : 2;
    return %orig(tv);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 2 && !searchIsActive) return [[self links] count];
    return %orig(tableView, section);
}

- (void)tableView:(id)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    if (ip.section == 2 && !searchIsActive) {
        NSString *pc = [[BDSettingsManager sharedManager] preferredClient];
        NSURL *defaultURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://redd.it/%@", [[self links][ip.row] url]]];
        if ([pc isEqualToString:@"Alien Blue"]) {
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"alienblue://example"]])
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"alienblue://thread/https://reddit.com/r/blank/comments/%@/_", [[self links][ip.row] url]]]];
            else
                [[UIApplication sharedApplication] openURL:defaultURL];
        } else if ([pc isEqualToString:@"Luna"]) {
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"luna://example"]])
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"luna://post/%@",[[self links][ip.row] url]]]];
            else
                [[UIApplication sharedApplication] openURL:defaultURL];
        } else if ([pc isEqualToString:@"AMRC"]) {
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"amrc://example"]])
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"amrc://redd.it/%@", [[self links][ip.row] url]]]];
            else
                [[UIApplication sharedApplication] openURL:defaultURL];
        } else
            [[UIApplication sharedApplication] openURL:defaultURL];
    } else {
        %orig(tv, ip);
    }
}

- (SPUISearchTableHeaderView *)tableView:(id)tv viewForHeaderInSection:(int)section {
    if (section == 2 && !searchIsActive) {
        SPUISearchTableHeaderView *v = %orig(tv, section);
        [v updateWithTitle:@"Spotit+" section:section isExpanded:YES];
        return v;
    }
    return %orig(tv, section);
}

%end


%hook SearchUITextAreaView

- (BOOL)updateWithResult:(SPSearchResult *)result formatter:(id)f {
    BOOL ret = %orig(result, f);
    UIView *secondToLast = [self valueForKey:@"secondToLastView"];
    if ([secondToLast class] == NSClassFromString(@"SearchUIRichTextField")) {
        UILabel *body = [secondToLast valueForKey:@"textLabel"];
        [body setText:[result body]];
    }
    return ret;
}

%end

%hook SPUISearchField

- (void)searchTextDidChange:(id)arg1 {
    %orig;
    if ([self.text length] > 0)
        searchIsActive = YES;
    else
        searchIsActive = NO;
}

%end
//////////////////////////////////////////
%end //iOS9
//////////////////////////////////////////

%ctor {
    [BDSettingsManager sharedManager];
    if ([[BDSettingsManager sharedManager] enabled]) {
        %init(iOS9);
    }
}
