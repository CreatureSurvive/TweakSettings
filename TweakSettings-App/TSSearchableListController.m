//
//  TSSearchableListController.m
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <Preferences/PSSpecifier.h>
#import "TSSearchableListController.h"

@interface TSSearchableListController ()

@end

@implementation TSSearchableListController {
    UISearchController *_searchController;
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
    } else {
        self.table.tableHeaderView = _searchController.searchBar;
    }

    self.unfilteredSpecifiers = self.specifiers;
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