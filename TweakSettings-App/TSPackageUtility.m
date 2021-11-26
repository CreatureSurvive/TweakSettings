//
// Created by Dana Buehre on 6/20/21.
//

#import <UIKit/UIKit.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListController.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import <CoreServices/CoreServices.h>
#import <dlfcn.h>

#import "TSPackageUtility.h"
#import "libprefs.h"

#pragma mark - LIBPREFS Shim

BOOL PREFERENCE_FILTER_PASSES_ENVIRONMENT_CHECKS(NSDictionary *filter) {
    BOOL valid = YES;
    NSArray *coreFoundationVersion;

    if (filter && (coreFoundationVersion = filter[@"CoreFoundationVersion"])) {
        if (coreFoundationVersion.count > 0) valid = valid && (kCFCoreFoundationVersionNumber >= [coreFoundationVersion[0] floatValue]); // lower
        if (coreFoundationVersion.count > 1) valid = valid && (kCFCoreFoundationVersionNumber < [coreFoundationVersion[1] floatValue]); // upper
    }

    return valid;
}

NSArray *SPECIFIERS_FROM_ENTRY(NSDictionary *entry, NSString *sourceBundlePath, NSString *title, PSListController *listController) {

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
}


@implementation TSPackageUtility {

}

#pragma mark - Member Methods

+ (NSArray<PSSpecifier *> *)loadTweakSpecifiersInController:(PSListController *)controller {
    NSMutableArray *preferenceSpecifiers = [NSMutableArray new];
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
                ? SPECIFIERS_FROM_ENTRY(plist[@"entry"], bundlePath, title, controller)
                : [controller specifiersFromEntry:plist[@"entry"] sourcePreferenceLoaderBundlePath:bundlePath title:title];

        if (itemSpecifiers && itemSpecifiers.count) {

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

+ (PSViewController *)controllerForSpecifier:(PSSpecifier *)specifier inController:(PSListController *)parentController {

    if ([parentController respondsToSelector:@selector(controllerForSpecifier:)]) {

        return [parentController performSelector:@selector(controllerForSpecifier:) withObject:specifier];
    }

    [specifier performControllerLoadAction];

    Class detailClass = [specifier respondsToSelector:@selector(detailControllerClass)]
            ? [specifier detailControllerClass]
            : [specifier valueForKey:@"detailControllerClass"]
                    ? : NSClassFromString(@"PLCustomListController")
                    ? : PSListController.class;

    if ([detailClass isSubclassOfClass:PSViewController.class]) {

        id controller = [detailClass alloc];
        controller = ([controller respondsToSelector:@selector(initForContentSize:)])
                ? [controller initForContentSize:UIScreen.mainScreen.bounds.size]
                : [controller init];

        if (controller && [controller isKindOfClass:PSViewController.class]) {

            [controller setRootController:parentController.rootController];
            [controller setParentController:parentController];
            [controller setSpecifier:specifier];
        }

        return controller;
    }

    return nil;
}

@end