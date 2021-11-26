//
//  TSSearchableListController.m
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <Preferences/PSSpecifier.h>
#import "TSSearchableListController.h"
#import "TSUserDefaults.h"

@interface TSSearchableListController ()

@end

@implementation TSSearchableListController {

    UISearchController *_searchController;
    BOOL _firstLoadComplete;
}

- (instancetype)init {

    if (self = [super init]) {

        _showOnLoad = YES;
    }

    return self;
}

- (instancetype)initForContentSize:(CGSize)contentSize {

    if (self = [super init]) {

        _showOnLoad = YES;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.searchBar.delegate = self;

    if (@available(iOS 11.0, *)) {
        self.navigationItem.searchController = _searchController;
        self.navigationController.navigationBar.prefersLargeTitles = TSUserDefaults.sharedDefaults.useLargeTitlesOnRootList;
    } else {
        self.table.tableHeaderView = _searchController.searchBar;
    }

    self.unfilteredSpecifiers = self.specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!_firstLoadComplete) {

        if (@available(iOS 11, *)) {
            self.navigationItem.hidesSearchBarWhenScrolling = NO;
            [self.navigationController.navigationBar sizeToFit];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];


    if (!_firstLoadComplete) {

        if (@available(iOS 11, *)) {
            self.navigationItem.hidesSearchBarWhenScrolling = !TSUserDefaults.sharedDefaults.alwaysShowSearchBar;
        }

        self->_firstLoadComplete = YES;
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(nonnull UISearchController *)searchController {

    __block NSString *searchText = searchController.searchBar.text;
    if (searchText && searchText.length > 0) {

        HIGH_QUEUE(^{
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[cd] %@", searchText];
            __block NSMutableArray *filteredSpecifiers = [self.unfilteredSpecifiers filteredArrayUsingPredicate:predicate].mutableCopy;

            MAIN_QUEUE_UNSAFE(^{
                self.specifiers = filteredSpecifiers;
                [self.table reloadData];
            });
        });
    } else {

        MAIN_QUEUE_UNSAFE(^{
            self.specifiers = self.unfilteredSpecifiers;
            [self.table reloadData];
        });
    }
}

#pragma mark - UISearchControllerDelegate

- (void)didDismissSearchController:(UISearchController *)searchController {

    MAIN_QUEUE_UNSAFE(^{
        self.specifiers = self.unfilteredSpecifiers;
        [self.table reloadData];
    });
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {

    MAIN_QUEUE_UNSAFE(^{
        self.specifiers = self.unfilteredSpecifiers;
        [self.table reloadData];
    });
}

@end