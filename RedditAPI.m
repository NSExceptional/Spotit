//
//  RedditAPI.m
//  Spotit
//
//  Created by Tanner on 11/3/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import "RedditAPI.h"

#define NSFormatString(...) [NSString stringWithFormat:__VA_ARGS__]
#define URL(string) [NSURL URLWithString:string]
#define APICallFailed(...) [TBSettingsManager sharedManager].APICallFailureDate = [NSDate date]; HBLogInfo(NSFormatString(__VA_ARGS__))

static NSString * const kAPILogin_user_user_password = @"api/login/%@?user=%@&passwd=%@&api_type=json";
static NSString * const kAPIFrontPageFeed_sort_limit = @"https://www.reddit.com/%@.json?limit=%@";
static NSString * const kAPIOAuthURL = @"https://www.reddit.com/api/v1/authorize?client_id=CLIENT_ID&response_type=TYPE&
    state=RANDOM_STRING&redirect_uri=URI&duration=DURATION&scope=SCOPE_STRING"


@implementation RedditAPI

- (void)authenticate:(void(^)())callback {
    NSURL *baseURL      = URL(@"https://ssl.reddit.com/");
    NSString *username  = [TBSettingsManager sharedManager].redditUsername;
    NSString *password  = [TBSettingsManager sharedManager].redditPassword;
    NSURL *loginURL     = [[NSURL URLWithString:NSFormatString(kAPILogin_user_user_password, username, username, password] relativeToURL:baseURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginURL];
    request.HTTPMethod = @"POST";
    [[NSURLSession sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            
            // Parse JSON
            NSError *jsonError = nil;
            NSDictionary *authJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                APICallFailed(@"Bad JSON %@", jsonError.localizedFailureReason);
                return;
            }
            
            // Login error handling
            if (authJson[@"json"][@"errors"]) {
                for (NSString *error in authJson[@"json"][@"errors"]) {
                    if ([error containsString:@"wrong"]) {
                        APICallFailed(@"Invalid login")
                        return;
                    }
                }
            }
            
            // Modhash and cookie
            NSDictionary *data = authJson[@"json"][@"data"];
            if (data[@"modhash"] && data[@"cookie"]) {
                
            }
        } else {
            APICallFailed(error.localizedFailureReason);
        }
    }] resume];
}

- (void)loadRedditDataAuth {
    NSURL *baseURL      = URL(@"https://ssl.reddit.com/");
    NSString *username  = [TBSettingsManager sharedManager].redditUsername;
    NSString *password  = [TBSettingsManager sharedManager].redditPassword;
    NSURL *loginURL     = [NSURL URLWithString:NSFormatString(kAPILogin_user_user_password, username, username, password) relativeToURL:baseURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginURL];
    request.HTTPMethod = @"POST";
    [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            
            // Parse JSON
            NSError *jsonError = nil;
            NSDictionary *authJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError) {
                APICallFailed(@"Bad JSON %@", jsonError.localizedFailureReason);
                return;
            }
            
            // Login error handling
            if (authJson[@"json"][@"errors"]) {
                for (NSString *error in authJson[@"json"][@"errors"]) {
                    if ([error containsString:@"wrong"]) {
                        APICallFailed(@"Invalid login")
                        return;
                    }
                }
            }
            
            // Modhash and cookie
            NSDictionary *data = authJson[@"json"][@"data"];
            if (data[@"modhash"] && data[@"cookie"]) {
                    
                HBLogInfo(@"the user was logged in successfully");
                NSString *feedURL = NSFormatString(kAPIFrontPageFeed_sort_limit, [TBSettingsManager sharedManager].sort, @([TBSettingsManager sharedManager].count));
                NSMutableURLRequest *meRequest = [[NSMutableURLRequest alloc] initWithURL:URL(feedURL]);
                meRequest.HTTPMethod = @"GET";
                
                [[NSURLSession sharedSession] dataTaskWithRequest:meRequest completionHandler:^(NSData *data1, NSURLResponse *response1, NSError *error1) {
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
                                    [result setBody:NSFormatString(@"%@...", [body substringToIndex:160]]);
                                } else {
                                    [result setBody:body];
                                }
                                
                                [result setSubtitle:link.subreddit];
                                [result setFootnote:NSFormatString(@"%@ – %@, %@", link.domain, link.score, link.age]);
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
        } else {
            APICallFailed(error.localizedFailureReason);
        }
    }] resume];
}

@end