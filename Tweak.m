#import <objc/runtime.h>
#import <CoreGraphics/CGAffineTransform.h>
#import "Interfaces.h"
#import "TBLink.h"
#import "SettingsManager.h"

BOOL searchIsActive;


%group iOS9

#include "SPSearchResult.m"

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

#include "SBSearchViewController.m"
#include "SPUISearchViewController.m"
#include "SPUISearchField_SearchUITextAreaView.m"

%end //iOS9
//////////////////////////////////////////

%ctor {
    [BDSettingsManager sharedManager];
    if ([[BDSettingsManager sharedManager] enabled]) {
        %init(iOS9);
    }
}
