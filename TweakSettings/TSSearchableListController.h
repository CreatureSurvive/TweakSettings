//
//  TSSearchableListController.h
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <UIKit/UIKit.h>
#import "PSListController.h"

@interface TSSearchableListController : PSListController <UISearchBarDelegate, UISearchResultsUpdating>

@property (nonatomic, strong) NSMutableArray<PSSpecifier *> *unfilteredSpecifiers;

@end
