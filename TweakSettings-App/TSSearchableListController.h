//
//  TSSearchableListController.h
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>

@class PSSpecifier;

@interface TSSearchableListController : PSListController <UISearchBarDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) NSMutableArray<PSSpecifier *> *unfilteredSpecifiers;
@property (nonatomic, assign) BOOL searchOnLoad;
@property (nonatomic, assign) BOOL showOnLoad;

@end
