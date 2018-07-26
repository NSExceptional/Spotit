//
//  Interfaces.h
//  Spotit
//
//  Created by Tanner in 2015.
//  Copyright © 2016 Tanner Bennett. All rights reserved.
//

#import <Foundation/Foundation.h>
@class TBLink;

@interface SearchUISingleResultTableViewCell : NSObject
- (id)initWithResult:(id)result style:(unsigned long)style;
- (void)updateWithResult:(id)result;
@property (assign) id result;
@end

@interface SPSearchResult : NSObject
@property (assign) NSString *title;
@property (assign) NSString *summary;
@property (assign) NSString *subtitle;
@property (assign) NSString *footnote;
@property (assign) NSString *url;
@property (assign) NSString *contentURL;
@property (assign) NSUInteger score;
@property (assign, readonly) NSMutableDictionary *additionalPropertyDict;
- (void)setNumberOfSummaryLines:(unsigned int)arg1;
@end

@interface SPSearchResult (TB)
- (NSString *)body;
- (void)setBody:(id)body;
- (void)setImage:(id)image;
@end

@interface SPUISearchTableHeaderView : UITableViewHeaderFooterView
- (void)updateWithTitle:(id)title section:(unsigned int)section isExpanded:(BOOL)expanded;
@end

@interface SPUISearchViewController : UIViewController
- (id)searchTableView;
- (BOOL)_isPullDownSpotlight;
@end

@interface SPUISearchViewController (TB) <UIViewControllerPreviewingDelegate>
@property (nonatomic) NSArray<TBLink*> *links;
@property (nonatomic, readonly) BOOL shouldShowFeedSection;
@end

@interface SPUISearchField : UITextField
@end
