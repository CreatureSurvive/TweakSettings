//
//  TSRootListController.m
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <Preferences/PSSpecifier.h>
#import <Preferences/PSRootController.h>
#import "TSRootListController.h"
#import "TSPackageUtility.h"
#import "TSAppDelegate.h"
#import "Localizable.h"
#import "TSRootNavigationManager.h"
#import "TSUserDefaults.h"
#import "TSOptionsController.h"

@interface UIBarButtonItem (iOS13)
- (id)initWithTitle:(NSString *)table menu:(UIMenu *)menu API_AVAILABLE(ios(13.0));
@end


@implementation TSRootListController {

    UIRefreshControl *_refreshControl;
}

- (instancetype)init {

    if (self = [super init]) {

        PSSpecifier *specifier = [PSSpecifier groupSpecifierWithName:@"Tweaks"];
        specifier.identifier = @"tweaks";
        self.specifier = specifier;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(ROOT_NAVIGATION_TITLE_KEY, nil);
    if (@available(iOS 14, *)) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(ROOT_NAVIGATION_RIGHT_TITLE_KEY, nil) menu:ActionListMenu()];
        [APP_DELEGATE setPopoverSender:self.navigationItem.rightBarButtonItem];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(ROOT_NAVIGATION_RIGHT_TITLE_KEY, nil) style:UIBarButtonItemStylePlain target:self action:@selector(_handleActionButtonTapped:)];
    }

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(ROOT_NAVIGATION_LEFT_TITLE_KEY, nil) style:UIBarButtonItemStylePlain target:self action:@selector(_handleOpenSettings:)];

    _refreshControl = [UIRefreshControl new];
    [_refreshControl addTarget:self action:@selector(_handleRefresh) forControlEvents:UIControlEventValueChanged];
    self.table.refreshControl = _refreshControl;

    [self _preferencesChanged];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_preferencesChanged) name:TSUserDefaultsChangedKey object:nil];

    _rootListLoaded = YES;
}

#pragma mark - PSListController

- (NSMutableArray *)specifiers {

    if (!_specifiers) {

        NSMutableArray *specifiers = [TSPackageUtility loadTweakSpecifiersInController:self].mutableCopy;

        self.specifiers = specifiers;
        self.unfilteredSpecifiers = specifiers;

        if (_refreshControl && _refreshControl.isRefreshing) {

            [_refreshControl endRefreshing];
        }
    }

    return _specifiers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    if (!cell.gestureRecognizers.count) {

        [cell addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_handleCellLongPress:)]];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (self.splitViewController.collapsed) {

        [super tableView:tableView didSelectRowAtIndexPath:indexPath];

    } else {

        PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
        [APP_DELEGATE.navigationManager pushDetailControllerForSpecifier:specifier];
    }
}

#pragma mark - Private Methods

- (void)_handleRefresh {

    _specifiers = nil;
    [self reloadSpecifiers];
}

- (void)_handleCellLongPress:(UILongPressGestureRecognizer *)sender {

    if (sender.state == UIGestureRecognizerStateBegan) {

        if (!TSUserDefaults.sharedDefaults.longPressOpensSettings) return;

        CGPoint point = [sender locationInView:self.table];
        NSIndexPath *indexPath = [self.table indexPathForRowAtPoint:point];
        PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
        NSString *urlString = [NSString stringWithFormat:@"prefs:root=%@", specifier.identifier];
        NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];

        [APP_DELEGATE openApplicationURL:url];
    }
}

- (void)_handleActionButtonTapped:(UIBarButtonItem *)sender {

    [APP_DELEGATE presentAsPopover:ActionListAlert() withSender:sender];
}

- (void)_handleOpenSettings:(UIBarButtonItem *)sender {

    [APP_DELEGATE presentAsPopover:[[UINavigationController alloc] initWithRootViewController:TSOptionsController.new] withSender:sender];
}

- (void)_preferencesChanged {

    if (@available(iOS 11, *)) {
        TSUserDefaults *defaults = TSUserDefaults.sharedDefaults;

        self.navigationItem.hidesSearchBarWhenScrolling = !defaults.alwaysShowSearchBar;
        self.navigationController.navigationBar.prefersLargeTitles = defaults.useLargeTitlesOnRootList;
        self.navigationItem.largeTitleDisplayMode = defaults.useLargeTitlesOnRootList
                ? UINavigationItemLargeTitleDisplayModeAlways
                : UINavigationItemLargeTitleDisplayModeNever;
    }
}

@end
