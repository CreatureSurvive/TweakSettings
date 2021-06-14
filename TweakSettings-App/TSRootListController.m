//
//  TSRootListController.m
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <CoreSpotlight/CoreSpotlight.h>
#import <CoreServices/CoreServices.h>
#import <Preferences/PSSpecifier.h>
#import <dlfcn.h>
#import "TSRootListController.h"
#import "TSAppDelegate.h"
#import "Localizable.h"
#import "libprefs.h"

@interface UIBarButtonItem (iOS14)
- (id)initWithTitle:(NSString *)table menu:(UIMenu *)menu API_AVAILABLE(ios(13.0));
@end

@interface TSRootListController ()

@end

@implementation TSRootListController {
    UIRefreshControl *_refreshControl;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(ROOT_NAVIGATION_TITLE_KEY, nil);
    if (@available(iOS 14, *)) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(ROOT_NAVIGATION_RIGHT_TITLE_KEY, nil) menu:ActionListMenu(self)];
    } else {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(ROOT_NAVIGATION_RIGHT_TITLE_KEY, nil) style:UIBarButtonItemStylePlain target:self action:@selector(handleActionButtonTapped:)];
    }

    _refreshControl = [UIRefreshControl new];
    [_refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    self.table.refreshControl = _refreshControl;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self pushToLaunchIdentifier];
}

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specifiers = [self loadTweakSpecifiers].mutableCopy;

        NSString *appVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        NSString *footerText = [NSString stringWithFormat:@"Tweak Settings — v%@\nCreatureCoding © 2021", appVersion];
        PSSpecifier *groupSpecifier = [PSSpecifier emptyGroupSpecifier];
        [groupSpecifier setProperty:footerText forKey:PSFooterTextGroupKey];
        [groupSpecifier setProperty:@1 forKey:PSFooterAlignmentGroupKey];
        [specifiers insertObject:groupSpecifier atIndex:0];

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
        [cell addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleCellLongPress:)]];
    }
    return cell;
}

- (void)handleCellLongPress:(UILongPressGestureRecognizer *)sender {

    if (sender.state == UIGestureRecognizerStateBegan) {

        CGPoint point = [sender locationInView:self.table];
        NSIndexPath *indexPath = [self.table indexPathForRowAtPoint:point];
        PSSpecifier *specifier = [self specifierAtIndexPath:indexPath];
        NSString *urlString = [NSString stringWithFormat:@"prefs:root=%@", specifier.identifier];
        NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];

        [(TSAppDelegate *)UIApplication.sharedApplication openApplicationURL:url];
    }
}

- (NSArray<PSSpecifier *> *)loadTweakSpecifiers {
    NSMutableArray *preferenceSpecifiers = [NSMutableArray new];

    BOOL (^PREFERENCE_FILTER_PASSES_ENVIRONMENT_CHECKS)(NSDictionary *) = ^BOOL (NSDictionary *filter) {
        BOOL valid = YES;
        NSArray *coreFoundationVersion;

        if (filter && (coreFoundationVersion = filter[@"CoreFoundationVersion"])) {
            if (coreFoundationVersion.count > 0) valid = valid && (kCFCoreFoundationVersionNumber >= [coreFoundationVersion[0] floatValue]); // lower
            if (coreFoundationVersion.count > 1) valid = valid && (kCFCoreFoundationVersionNumber < [coreFoundationVersion[1] floatValue]); // upper
        }

        return valid;
    };

    NSArray *(^SPECIFIERS_FROM_ENTRY)(NSDictionary *, NSString *, NSString *, PSListController *) = ^NSArray * (NSDictionary *entry, NSString *sourceBundlePath, NSString *title, PSListController *listController) {

        NSString *bundleName = entry[@"bundle"];
        NSString *bundlePath = entry[@"bundlePath"];
        NSDictionary *specifierPlist = @{ @"items" : @[entry] };
        BOOL isBundle = bundleName != nil;

        if (isBundle) {
            NSFileManager *fileManger = NSFileManager.defaultManager;
            if (![fileManger fileExistsAtPath:bundlePath])
                bundlePath = [NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle", bundleName];
            if (![fileManger fileExistsAtPath:bundlePath])
                bundlePath = [NSString stringWithFormat:@"/System/Library/PreferenceBundles/%@.bundle", bundleName];
            if (![fileManger fileExistsAtPath:bundlePath]) {
                return nil;
            }
        }

        NSBundle *prefBundle = [NSBundle bundleWithPath:(isBundle ? bundlePath : sourceBundlePath)];
        NSMutableArray *bundleControllers = [listController valueForKey:@"_bundleControllers"];

        void *handle = dlopen("/System/Library/PrivateFrameworks/Preferences.framework/Preferences", RTLD_LAZY);
        NSArray *(*_SpecifiersFromPlist)(NSDictionary *,PSSpecifier *,id ,NSString *,NSBundle *,NSString **,NSString **,PSListController *,NSMutableArray **) = dlsym(handle, "SpecifiersFromPlist");
        NSArray *specs = _SpecifiersFromPlist(specifierPlist, nil, listController, title, prefBundle, NULL, NULL, listController, &bundleControllers);

        if (!specs.count) return nil;

        if (isBundle) {
            if ([entry[PSBundleIsControllerKey] boolValue]) {
                for (PSSpecifier *specifier in specs) {
                    [specifier setProperty:bundlePath forKey:PSLazilyLoadedBundleKey];
                    [specifier setProperty:[NSBundle bundleWithPath:sourceBundlePath] forKey:@"pl_bundle"];
                    if (!specifier.name) specifier.name = title;
                }
            }
        } else {
            Class customClass = NSClassFromString(@"PLCustomListController");
            Class localizedClass = NSClassFromString(@"PLLocalizedListController");
            BOOL isLocalizedBundle = ![sourceBundlePath.lastPathComponent isEqualToString:@"Preferences"];

            if ((isLocalizedBundle && localizedClass) || customClass) {

                PSSpecifier *specifier = specs.firstObject;
                [specifier setValue:(isLocalizedBundle ? localizedClass : customClass) forKey:@"detailControllerClass"];
                [specifier setProperty:prefBundle forKey:@"pl_bundle"];

                if (![specifier.properties[PSTitleKey] isEqualToString:title]) {
                    [specifier setProperty:title forKey:@"pl_alt_plist_name"];
                    if (!specifier.name) specifier.name = title;
                }
            }
        }

        return specs;
    };

    NSArray *preferenceBundlePaths = [NSFileManager.defaultManager subpathsOfDirectoryAtPath:@"/Library/PreferenceLoader/Preferences" error:nil];
    NSMutableArray *searchableItems = [NSMutableArray new];

    for (NSString *item in preferenceBundlePaths)
    {
        if (![item.pathExtension isEqualToString:@"plist"]) continue;

        NSString *plistPath = [NSString stringWithFormat:@"/Library/PreferenceLoader/Preferences/%@", item];
        NSDictionary *plist = DICTIONARY_WITH_PLIST(plistPath);

        if (!plist[@"entry"]) continue;
        if (!PREFERENCE_FILTER_PASSES_ENVIRONMENT_CHECKS(plist[@"filter"] ?: plist[@"pl_filter"])) continue;
        if (!PREFERENCE_FILTER_PASSES_ENVIRONMENT_CHECKS(plist[@"entry"][@"pl_filter"])) continue;

        NSString *bundlePath = [plistPath stringByDeletingLastPathComponent];
        NSString *title = [item.lastPathComponent stringByDeletingPathExtension];
        BOOL customInstall = access("/var/lib/dpkg/info/com.artikus.preferenceloader.list", F_OK) == 0
                || access("/var/lib/dpkg/info/com.creaturecoding.preferred.list", F_OK) == 0;

        NSArray *itemSpecifiers = !customInstall
                ? SPECIFIERS_FROM_ENTRY(plist[@"entry"], bundlePath, title, self)
                : [self specifiersFromEntry:plist[@"entry"] sourcePreferenceLoaderBundlePath:bundlePath title:title];

        if (itemSpecifiers && itemSpecifiers.count)
        {
            for (PSSpecifier *specifier in itemSpecifiers)
            {
                if (![specifier propertyForKey:PSIconImageKey]) {
                    [specifier setProperty:[UIImage imageNamed:@"tweak"] forKey:PSIconImageKey];
                }

                CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *) kUTTypeImage];
                attributeSet.title = specifier.name;
                attributeSet.contentDescription = [NSString stringWithFormat:@"Tweak Settings \u2192 %@", specifier.name];
                attributeSet.thumbnailData = UIImagePNGRepresentation([specifier propertyForKey:PSIconImageKey]);
                attributeSet.keywords = @[@"tweaks", @"packages", @"jailbreak", specifier.name];

                NSString *uniqueIdentifier = [NSString stringWithFormat:@"%@", specifier.identifier];
                CSSearchableItem *searchItem = [[CSSearchableItem alloc] initWithUniqueIdentifier:uniqueIdentifier domainIdentifier:@"com.creaturecoding.tweaksettings" attributeSet:attributeSet];
                [searchableItems addObject:searchItem];
            }

            [preferenceSpecifiers addObjectsFromArray:itemSpecifiers];
        }
    }

    if (preferenceSpecifiers.count) {
        [preferenceSpecifiers sortUsingDescriptors:@[
                [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]
        ];
    }

    [CSSearchableIndex.defaultSearchableIndex deleteAllSearchableItemsWithCompletionHandler:^(NSError *error) {
        [CSSearchableIndex.defaultSearchableIndex indexSearchableItems:searchableItems completionHandler:nil];
    }];

    return preferenceSpecifiers;
}

- (void)handleRefresh {
    _specifiers = nil;
    [self reloadSpecifiers];
}

- (void)handleActionButtonTapped:(UIBarButtonItem *)sender {

    [self.navigationController presentViewController:ActionListAlert(sender) animated:YES completion:nil];
}

- (void)pushToLaunchIdentifier {

    if (_launchIdentifier) {
        PSSpecifier *specifier = [self specifierForID:_launchIdentifier];

        if (specifier) {

            [specifier performControllerLoadAction];

            Class detailClass = [specifier respondsToSelector:@selector(detailControllerClass)]
                    ? [specifier detailControllerClass]
                    : [specifier valueForKey:@"detailControllerClass"]
                            ? : NSClassFromString(@"PLCustomListController");

            if ([detailClass isSubclassOfClass:PSViewController.class]) {

                id controller = [detailClass alloc];
                controller = ([controller respondsToSelector:@selector(initForContentSize:)])
                        ? [controller initForContentSize:UIScreen.mainScreen.bounds.size]
                        : [controller init];

                if (controller && [controller isKindOfClass:PSViewController.class]) {

                    [controller setRootController:self.rootController];
                    [controller setParentController:self];
                    [controller setSpecifier:specifier];
                }

                [self.navigationController pushViewController:controller animated:NO];
            }
        }
    }

    _launchIdentifier = nil;
}

@end
