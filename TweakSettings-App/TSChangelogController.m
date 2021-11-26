//
// Created by Dana Buehre on 11/21/21.
//

#import <UIKit/UIKit.h>
#import "TSChangelogController.h"
#import <Preferences/PSSpecifier.h>


@implementation TSChangelogController {

    NSArray *_releases;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self _loadChangelog];
}

#pragma mark - PSListController

- (NSMutableArray *)specifiers {

    if (!_specifiers) {

        if (_releases) {

            NSMutableArray *specifiers = [NSMutableArray new];

            for (NSDictionary *release in _releases) {

                [specifiers addObject:[PSSpecifier groupSpecifierWithName:release[@"version"]]];

                for (NSString *change in release[@"changes"]) {

                    [specifiers addObject:[PSSpecifier preferenceSpecifierNamed:change target:nil set:nil get:nil detail:nil cell:PSStaticTextCell edit:nil]];
                }
            }

            _specifiers = specifiers;
        }

        else {

            _specifiers = @[[PSSpecifier preferenceSpecifierNamed:nil target:nil set:nil get:nil detail:nil cell:PSSpinnerCell edit:nil]].mutableCopy;
        }
    }

    return _specifiers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;
    return cell;
}

#pragma mark - Private Methods

- (void)_loadChangelog {

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURL *latestReleaseURL = [NSURL URLWithString:@"https://api.creaturecoding.com/info/package?id=tweaksettings&key=changelog"];

    [[session dataTaskWithURL:latestReleaseURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        if (!data || error) {
            return;
        }

        NSArray *releases = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:nil];
        if (!releases || !releases.count) {
            return;
        }

        self->_releases = releases;

        MAIN_QUEUE(^{ [self reloadSpecifiers]; });

    }] resume];
}

@end