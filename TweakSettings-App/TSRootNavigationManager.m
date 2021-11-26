//
//  TSRootNavigationManager.m
//  TweakSettings
//
//  Created by Dana Buehre on 11/9/21.
//
//

#import <UIKit/UIKit.h>
#import <Preferences/PSSplitViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "TSRootNavigationManager.h"
#import "TSPrefsRootController.h"
#import "TSRootListController.h"
#import "TSPackageUtility.h"
#import "TSSplitViewController.h"

@interface TSRootNavigationManager () <UISplitViewControllerDelegate, PSSplitViewControllerNavigationDelegate, UINavigationControllerDelegate>

@property(nonatomic, strong, readonly) NSArray<PSViewController *> *navigationStack;
@property(nonatomic, strong, readonly) PSListController *blankListController;

@end

@implementation TSRootNavigationManager

- (instancetype)init
{
    if (self = [super init]) {

        _blankListController = PSListController.new;
        _splitController = TSSplitViewController.new;
        _rootListController = TSRootListController.new;
        _navigationController = [[UINavigationController alloc] initWithRootViewController:_rootListController];
        _rootController = [[TSPrefsRootController alloc] initWithRootViewController:_blankListController rootListController:_rootListController];
        _rootListController.rootController = _rootController;
        _splitController.delegate = self;
        _splitController.navigationDelegate = self;
        _splitController.preferredDisplayMode = UISplitViewControllerDisplayModeAllVisible;
        _splitController.containerNavigationController = _rootController;
        [_splitController setViewControllers:@[_navigationController, _rootController]];
        [_rootController setSupportedInterfaceOrientations:_splitController.supportedInterfaceOrientations];
        _navigationController.delegate = self;
        _rootController.delegate = self;
    }

    return self;
}

#pragma mark - UISplitViewControllerDelegate

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    [self _getCurrentNavigationStack];
    [_rootController setViewControllers:_navigationStack animated:NO];
    return NO;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
{

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT (SELF isKindOfClass: %@) && SELF != %@", UINavigationController.class, _rootListController];
    NSMutableArray *viewControllers = [_rootListController.navigationController.viewControllers filteredArrayUsingPredicate:predicate].mutableCopy;

    if (!viewControllers || !viewControllers.count) {

        viewControllers = (_navigationStack && _navigationStack.count ? _navigationStack : @[_blankListController]).mutableCopy;
    }

    [_navigationController popToRootViewControllerAnimated:NO];
    [_rootController setViewControllers:viewControllers animated:NO];

    [self _resetNavigationAppearance:_navigationController];
    [self _resetNavigationAppearance:_rootController];

    return _rootController;
}

#pragma mark - PSSplitViewControllerNavigationDelegate

- (void)splitViewControllerDidPopToRootController:(id)splitViewController
{
    [self _resetNavigationAppearance:_navigationController];
    [self _resetNavigationAppearance:_rootController];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self _getCurrentNavigationStack];

    if (_deferredLoadURL) {

       [self processDeferredURL:NO];
    }
}

#pragma mark - Public Methods

- (UIViewController *)topViewController
{
    return self.isCollapsed ? _navigationController.topViewController : _rootController.topViewController;
}

- (UINavigationController *)topNavigationController
{
    return self.isCollapsed ? _navigationController : (typeof(_navigationController))_rootController;
}

- (BOOL)isCollapsed
{
    return _splitController.collapsed;
}

- (NSURL *)urlForCurrentNavStack {
    NSMutableString *path = @"tweaks:root=".mutableCopy;
    NSArray *viewControllers = self.topNavigationController.viewControllers;

    for (int i = 1; i < viewControllers.count; ++i) {
        PSViewController *controller = viewControllers[(NSUInteger) i];
        if (!controller.specifier) continue;
        [path appendFormat:(i > 1 ? @"/%@" : @"%@"), controller.specifier.identifier];
    }

    return [NSURL URLWithString:[path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLFragmentAllowedCharacterSet]];
}

- (void)processDeferredURL:(BOOL)animated {
    [self processURL:_deferredLoadURL animated:animated];
    _deferredLoadURL = nil;
}

- (void)processURL:(NSURL *)url animated:(BOOL)animated {
    if (!url) return;

    NSString * pathString = [url.absoluteString.stringByRemovingPercentEncoding stringByReplacingOccurrencesOfString:@"tweaks:root=" withString:@""];
    NSArray *components = [pathString componentsSeparatedByString:@"/"];
    NSMutableArray *controllers = [NSMutableArray new];
    PSListController *parentController = _rootListController;

    for (NSString *identifier in components)
    {
        if (!parentController) break;
        PSSpecifier *specifier = [parentController specifierForID:identifier];
        if (!specifier) break;
        PSViewController *controller = [TSPackageUtility controllerForSpecifier:specifier inController:parentController];
        if (!controller) break;
        [controllers addObject:controller];

        parentController = ([controller isKindOfClass:PSListController.class]) ? (PSListController *)controller : nil;
    }

    if (self.isCollapsed) {

        [controllers insertObject:_rootListController atIndex:0];
    }

    [self.topNavigationController setViewControllers:controllers animated:animated];
}

- (void)pushDetailControllerForSpecifier:(PSSpecifier *)specifier {
    PSViewController *controller = [TSPackageUtility controllerForSpecifier:specifier inController:_rootListController];

    if (controller) {

        [self.topNavigationController setViewControllers:@[controller] animated:NO];
        [self _resetNavigationAppearance:self.rootController];
    }
}

#pragma mark - Private Methods

- (void)_resetNavigationAppearance:(UINavigationController *)controller {
    [controller.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [controller.navigationBar setShadowImage:nil];
    [controller.navigationBar setTintColor:nil];
    [controller.navigationBar setBarTintColor:nil];
    [controller.navigationBar setTitleTextAttributes:nil];
    if (@available(iOS 11, *)) {

        [controller.navigationBar setLargeTitleTextAttributes:nil];
    }
}

- (void)_getCurrentNavigationStack {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF != %@", _blankListController];
    NSArray *viewControllers = [_rootController.viewControllers filteredArrayUsingPredicate:predicate];
    _navigationStack = viewControllers;
}

@end
