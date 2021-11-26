//
// Created by Dana Buehre on 6/20/21.
//

#import <Foundation/Foundation.h>

@class PSListController;

BOOL PREFERENCE_FILTER_PASSES_ENVIRONMENT_CHECKS(NSDictionary *filter);
NSArray *SPECIFIERS_FROM_ENTRY(NSDictionary *entry, NSString *sourceBundlePath, NSString *title, PSListController *listController);

@interface TSPackageUtility : NSObject

+ (NSArray<PSSpecifier *> *)loadTweakSpecifiersInController:(PSListController *)controller;
+ (PSViewController *)controllerForSpecifier:(PSSpecifier *)specifier inController:(PSListController *)parentController;

@end