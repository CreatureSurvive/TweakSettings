//
//  TSRootListController.m
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <Preferences/PSSpecifier.h>
#import <dlfcn.h>
#import "TSRootListController.h"
#import "Localizable.h"
#import "libprefs.h"
#import "TSAppDelegate.h"

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
        NSArray *bundleControllers = [listController valueForKey:@"_bundleControllers"];

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

    for (NSString *item in preferenceBundlePaths)
    {
        if (![item.pathExtension isEqualToString:@"plist"]) continue;

        NSString *plistPath = [NSString stringWithFormat:@"/Library/PreferenceLoader/Preferences/%@", item];
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];

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
            [preferenceSpecifiers addObjectsFromArray:itemSpecifiers];
        }
    }

    if (preferenceSpecifiers.count) {
        [preferenceSpecifiers sortUsingDescriptors:@[
                [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]
        ];
    }

    return preferenceSpecifiers;
}

- (void)handleRefresh {
    _specifiers = nil;
    [self reloadSpecifiers];
}

- (void)handleActionButtonTapped:(UIBarButtonItem *)sender {

    [self.navigationController presentViewController:ActionListAlert(sender) animated:YES completion:nil];
}

@end
