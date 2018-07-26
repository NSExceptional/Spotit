//
//  SPUISearchField_SearchUITextAreaView.m
//  Spotit
//
//  Created by Tanner on 11/3/16.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

%hook SPUISearchField

- (void)searchTextDidChange:(id)arg1 {
    %orig(arg1);
    
    if (self.text.length) {
        searchIsActive = YES;
    } else {
        searchIsActive = NO;
    }
}

%end
    
%hook SearchUITextAreaView

- (BOOL)updateWithResult:(SPSearchResult *)result formatter:(id)f {
    BOOL ret = %orig(result, f);
    
    UIView *secondToLast = [self valueForKey:@"secondToLastView"];
    if ([secondToLast class] == NSClassFromString(@"SearchUIRichTextField")) {
        UILabel *body = [secondToLast valueForKey:@"textLabel"];
        body.text = result.body;
    }
    
    return ret;
}

%end
    