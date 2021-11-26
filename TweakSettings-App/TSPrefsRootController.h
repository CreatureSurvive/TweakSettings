//
// Created by Dana Buehre on 11/6/21.
//

#import <Preferences/PSRootController.h>

@class TSRootListController;

@interface TSPrefsRootController : PSRootController

@property (nonatomic, strong, readonly) TSRootListController *rootListController;

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController rootListController:(TSRootListController *)rootListController;

- (instancetype)initWithRootListController:(TSRootListController *)rootListController;

@end