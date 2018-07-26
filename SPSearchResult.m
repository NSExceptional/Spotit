//
//  SPSearchResult.m
//  Spotit
//
//  Created by Tanner on 11/3/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

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