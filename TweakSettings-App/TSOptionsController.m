//
//  TSOptionsController.m
//  TweakSettings
//
//  Created by Dana Buehre on 11/14/21.
//
//

#import <Preferences/PSSpecifier.h>
#import <Preferences/PSListItemsController.h>
#import "TSOptionsController.h"
#import "TSUserDefaults.h"
#import "Localizable.h"
#import "TSChangelogController.h"

@implementation TSOptionsController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = self.title;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_dismiss)];
}

#pragma mark - PSListController

- (NSString *)title {
    return NSLocalizedString(APP_SETTINGS_TITLE_NAME_KEY, nil);
}

- (NSMutableArray *)specifiers {

    if (!_specifiers) {

        NSMutableArray *specifiers = @[
                [self groupSpecifierNamed:nil footer:NSLocalizedString(REQUIRE_ACTION_CONFIRMATION_GROUP_KEY, nil)],
                [self specifierNamed:NSLocalizedString(REQUIRE_ACTION_CONFIRMATION_NAME_KEY, nil) key:RequireActionConfirmationKey default:@(YES) cellType:PSSwitchCell],
                [self groupSpecifierNamed:nil footer:NSLocalizedString(LONG_PRESS_OPENS_SETTINGS_GROUP_KEY, nil)],
                [self specifierNamed:NSLocalizedString(LONG_PRESS_OPENS_SETTINGS_NAME_KEY, nil) key:LongPressOpensSettingsKey default:@(YES) cellType:PSSwitchCell],
        ].mutableCopy;

        if (@available(iOS 11, *)) {
            [specifiers insertObject:[self groupSpecifierNamed:nil footer:NSLocalizedString(USE_LARGE_TITLES_ON_ROOT_LIST_GROUP_KEY, nil)] atIndex:0];
            [specifiers insertObject:[self specifierNamed:NSLocalizedString(USE_LARGE_TITLES_ON_ROOT_LIST_NAME_KEY, nil) key:UseLargeTitlesOnRootListKey default:@(YES) cellType:PSSwitchCell] atIndex:1];
            [specifiers insertObject:[self groupSpecifierNamed:nil footer:NSLocalizedString(ALWAYS_SHOW_SEARCH_BAR_GROUP_KEY, nil)] atIndex:2];
            [specifiers insertObject:[self specifierNamed:NSLocalizedString(ALWAYS_SHOW_SEARCH_BAR_NAME_KEY, nil) key:AlwaysShowSearchBarKey default:@(NO) cellType:PSSwitchCell] atIndex:3];
        }

        [specifiers addObjectsFromArray:[self _footerSpecifiers]];

        _specifiers = specifiers;
    }

    return _specifiers;
}

#pragma mark - Public Methods

- (PSSpecifier *)specifierNamed:(NSString *)name key:(NSString *)key default:(id)defaultValue cellType:(PSCellType)cellType {

    PSSpecifier *specifier = [PSSpecifier preferenceSpecifierNamed:name target:self set:@selector(setPreferenceValue:specifier:) get:@selector(readPreferenceValue:) detail:nil cell:cellType edit:nil];
    [specifier setProperty:key forKey:PSKeyNameKey];
    [specifier setProperty:defaultValue forKey:PSDefaultValueKey];
    [specifier setProperty:@"com.creaturecoding.tweaksettings" forKey:PSDefaultsKey];
    [specifier setProperty:@"com.creaturecoding.tweaksettings/changed" forKey:PSValueChangedNotificationKey];

    return specifier;
}

- (PSSpecifier *)groupSpecifierNamed:(NSString *)name footer:(NSString *)footer {

    PSSpecifier *specifier = [PSSpecifier groupSpecifierWithName:name];
    [specifier setProperty:footer forKey:PSFooterTextGroupKey];
    return specifier;
}

#pragma mark - Private Methods

- (void)_dismiss {

    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)_openLink:(PSSpecifier *)specifier {

    NSURL *url = [specifier propertyForKey:@"openURL"];
    [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}

- (NSArray <PSSpecifier *> *)_footerSpecifiers {

    PSSpecifier *developerGroupSpecifier = [PSSpecifier emptyGroupSpecifier];
    [developerGroupSpecifier setProperty:@"CreatureCoding © 2023" forKey:PSFooterTextGroupKey];
    [developerGroupSpecifier setProperty:@1 forKey:PSFooterAlignmentGroupKey];

    PSSpecifier *changelogSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Changelog" target:self set:nil get:nil detail:TSChangelogController.class cell:PSLinkCell edit:nil];

    PSSpecifier *sourceSpecifier = [PSSpecifier preferenceSpecifierNamed:NSLocalizedString(SOURCE_CODE_NAME_KEY, nil) target:self set:nil get:nil detail:nil cell:PSLinkCell edit:nil];
    [sourceSpecifier setProperty:[NSURL URLWithString:@"https://github.com/CreatureSurvive/TweakSettings"] forKey:@"openURL"];
    sourceSpecifier->action = @selector(_openLink:);

    PSSpecifier *versionSpecifier = [PSSpecifier preferenceSpecifierNamed:NSLocalizedString(APP_VERSION_NAME_KEY, nil) target:self set:nil get:@selector(_valueForSpecifier:) detail:nil cell:PSTitleValueCell edit:nil];
    [versionSpecifier setProperty:[NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forKey:PSValueKey];
    versionSpecifier->action = @selector(_checkForUpdates);

    return @[developerGroupSpecifier, changelogSpecifier, sourceSpecifier, versionSpecifier];
}

- (NSString *)_valueForSpecifier:(PSSpecifier *)specifier {

    return [specifier propertyForKey:PSValueKey];
}

- (void)_checkForUpdates {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    [configuration setRequestCachePolicy:NSURLRequestReloadIgnoringCacheData];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURL *latestReleaseURL = [NSURL URLWithString:@"https://api.creaturecoding.com/info/package?id=tweaksettings&key=package.version"];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(CHECK_FOR_UPDATES_TITLE_KEY, nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    MAIN_QUEUE(^{ [self.navigationController presentViewController:alertController animated:NO completion:nil]; });

    [[session dataTaskWithURL:latestReleaseURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        void (^updateAlert)(NSString *, NSString *, BOOL ) = ^(NSString *title, NSString *message, BOOL error) {
            MAIN_QUEUE(^{
                if (title) alertController.title = title;
                if (message) alertController.message = message;
                if (error) alertController.message = NSLocalizedString(CHECK_FOR_UPDATES_ERROR_MESSAGE_KEY, nil);
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(ALERT_DISMISS_TITLE_KEY, nil) style:UIAlertActionStyleCancel handler:nil]];
            });
        };

        if (!data || error) {
            updateAlert(nil, nil, YES);
            return;
        }

        NSString *key = @"version";
        NSDictionary *release = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:nil];
        if (!release || !release[key] || ![release[key] length]) {
            updateAlert(nil, nil, YES);
            return;
        }

        NSString *message;
        NSString *releaseVersion = release[key];
        NSString *localVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        BOOL updateAvailable = ![releaseVersion isEqualToString:localVersion];

        message = [NSString stringWithFormat:updateAvailable
                        ? NSLocalizedString(CHECK_FOR_UPDATES_FAIL_MESSAGE_KEY, nil)
                        : NSLocalizedString(CHECK_FOR_UPDATES_PASS_MESSAGE_KEY, nil), releaseVersion];

        updateAlert(nil, message, NO);

    }] resume];
}

@end
