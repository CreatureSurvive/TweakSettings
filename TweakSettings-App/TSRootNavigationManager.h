//
//  TSRootNavigationManager.h
//  TweakSettings
//
//  Created by Dana Buehre on 11/9/21.
//
//



@class TSPrefsRootController;
@class TSRootListController;
@class TSSplitViewController;
@class UINavigationController;
@class PSListController;

NS_ASSUME_NONNULL_BEGIN

#define NAVIGATION_MANAGER APP_DELEGATE.navigationController

@interface TSRootNavigationManager : NSObject

@property(nonatomic, strong) NSURL *deferredLoadURL;

@property(nonatomic, strong, readonly) TSPrefsRootController *rootController;
@property(nonatomic, strong, readonly) TSRootListController *rootListController;
@property(nonatomic, strong, readonly) TSSplitViewController *splitController;
@property(nonatomic, strong, readonly) UINavigationController *navigationController;


- (__kindof UIViewController *)topViewController;
- (__kindof UINavigationController *)topNavigationController;
- (BOOL)isCollapsed;

- (NSURL *)urlForCurrentNavStack;
- (void)processDeferredURL:(BOOL)animated;
- (void)processURL:(NSURL *)url animated:(BOOL)animated;
- (void)pushDetailControllerForSpecifier:(PSSpecifier *)specifier;

@end

NS_ASSUME_NONNULL_END
