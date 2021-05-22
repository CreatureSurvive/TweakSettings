//
//  TSRootListController.m
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import "TSRootListController.h"
#import "PSSpecifier.h"
#import "Localizable.h"
#import "libprefs.h"

@interface TSRootListController ()

@end

@implementation TSRootListController
{
    UIRefreshControl *_refreshControl;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(ROOT_NAVIGATION_TITLE, nil);

    _refreshControl = [UIRefreshControl new];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    self.table.refreshControl = _refreshControl;
}

- (NSMutableArray *)specifiers
{
    if (!_specifiers)
    {
        NSMutableArray *specifiers = [self loadTweakSpecifiers].mutableCopy;
        [specifiers sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];

        NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *footerText = [NSString stringWithFormat:@"Tweak Settings - v%@\nCreatureCoding © 2021", appVersion];
        PSSpecifier *groupSpecifier = [PSSpecifier emptyGroupSpecifier];
        [groupSpecifier setProperty:footerText forKey:PSFooterTextGroupKey];
        [groupSpecifier setProperty:@1 forKey:PSFooterAlignmentGroupKey];
        [specifiers addObject:groupSpecifier];

        self.specifiers = specifiers;
        self.unfilteredSpecifiers = specifiers;

        if (_refreshControl && _refreshControl.isRefreshing) {
            [_refreshControl endRefreshing];
        }
    }

    return _specifiers;
}

- (void)handleRefresh
{
    _specifiers = nil;
    [self reloadSpecifiers];
}

- (NSArray<PSSpecifier *> *)loadTweakSpecifiers
{
    NSMutableArray *preferenceSpecifiers = [NSMutableArray new];

    if ([PSSpecifier respondsToSelector:@selector(environmentPassesPreferenceLoaderFilter:)] ||
        [self respondsToSelector:@selector(specifiersFromEntry:sourcePreferenceLoaderBundlePath:title:)])
    {

        NSArray *preferenceBundlePaths = [NSFileManager.defaultManager subpathsOfDirectoryAtPath:@"/Library/PreferenceLoader/Preferences" error:nil];

        for (NSString *item in preferenceBundlePaths)
        {
            if (![item.pathExtension isEqualToString:@"plist"]) continue;

            NSString *plistPath = [NSString stringWithFormat:@"/Library/PreferenceLoader/Preferences/%@", item];
            NSDictionary *plist = DICTIONARY_WITH_PLIST(plistPath);

            if (!plist[@"entry"]) continue;
            if (![PSSpecifier environmentPassesPreferenceLoaderFilter:(plist[@"filter"] ? : plist[@"pl_filter"])]) continue;
            if (![PSSpecifier environmentPassesPreferenceLoaderFilter:plist[@"entry"][@"pl_filter"]]) continue;

            NSString *bundlePath = [plistPath stringByDeletingLastPathComponent];
            NSString *title = [item.lastPathComponent stringByDeletingPathExtension];
            NSArray *itemSpecifiers = [self specifiersFromEntry:plist[@"entry"] sourcePreferenceLoaderBundlePath:bundlePath title:title];

            if (itemSpecifiers && itemSpecifiers.count)
            {
                [preferenceSpecifiers addObjectsFromArray:itemSpecifiers];
            }
        }
    }

    if (preferenceSpecifiers.count)
    {
        [preferenceSpecifiers sortUsingComparator: ^(PSSpecifier *specifier1, PSSpecifier *specifier2) {
            return [specifier1.name localizedCaseInsensitiveCompare:specifier2.name];
        }];

        [preferenceSpecifiers insertObject:[PSSpecifier emptyGroupSpecifier] atIndex:0];
    }

    return preferenceSpecifiers;
}

@end
