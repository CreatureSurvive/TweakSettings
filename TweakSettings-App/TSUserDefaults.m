//
// Created by Dana Buehre on 11/13/21.
//

#import "TSUserDefaults.h"

@interface TSUserDefaults ()
- (void)_preferenceNotificationReceived;
@end

static void ReceivedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    if (observer) [(__bridge TSUserDefaults *) observer _preferenceNotificationReceived];
}

@implementation TSUserDefaults {
    NSString *_bundleIdentifier;
    NSString *_preferencesChangedIdentifier;
    NSString *_preferencePath;
}

+ (instancetype)sharedDefaults {
    static TSUserDefaults *userDefaults;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userDefaults = [TSUserDefaults new];
    });

    return userDefaults;
}

- (instancetype)init {
    if (self = [super init]) {

        _bundleIdentifier = @"com.creaturecoding.tweaksettings";
        _preferencesChangedIdentifier = @"com.creaturecoding.tweaksettings/changed";
        _preferencePath = [NSHomeDirectory() stringByAppendingFormat:@"/Library/Preferences/%@.plist", _bundleIdentifier];

        _defaults = NSUserDefaults.standardUserDefaults;
        
        CFNotificationCenterAddObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                (__bridge void *) self,
                (CFNotificationCallback) ReceivedNotification,
                (__bridge CFStringRef) _preferencesChangedIdentifier,
                NULL,
                CFNotificationSuspensionBehaviorCoalesce
        );

        [self _setDefaults];
    }
    
    return self;
}

#pragma mark - Properties

- (BOOL)useLargeTitlesOnRootList {

    return [self.defaults boolForKey:UseLargeTitlesOnRootListKey];
}

- (void)setUseLargeTitlesOnRootList:(BOOL)useLargeTitlesOnRootList {

    [self.defaults setBool:useLargeTitlesOnRootList forKey:UseLargeTitlesOnRootListKey];
}

- (BOOL)alwaysShowSearchBar {

    return [self.defaults boolForKey:AlwaysShowSearchBarKey];
}

- (void)setAlwaysShowSearchBar:(BOOL)alwaysShowSearchBar {

    [self.defaults setBool:alwaysShowSearchBar forKey:AlwaysShowSearchBarKey];
}

- (BOOL)requireActionConfirmation {

    return [self.defaults boolForKey:RequireActionConfirmationKey];
}

- (void)setRequireActionConfirmation:(BOOL)requireActionConfirmation {

    [self.defaults setBool:requireActionConfirmation forKey:RequireActionConfirmationKey];
}

- (BOOL)longPressOpensSettings {

    return [self.defaults boolForKey:LongPressOpensSettingsKey];
}

- (void)setLongPressOpensSettings:(BOOL)longPressOpensSettings {

    [self.defaults setBool:longPressOpensSettings forKey:LongPressOpensSettingsKey];
}

- (void)synchronize {

    CFPreferencesSynchronize(
            (__bridge CFStringRef) _bundleIdentifier,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
    );
}

#pragma mark - Private Methods

- (void)_preferenceNotificationReceived {

    [self synchronize];
    [NSNotificationCenter.defaultCenter postNotificationName:TSUserDefaultsChangedKey object:nil];
}

- (void)_setDefaults {

    NSUserDefaults *defaults = self.defaults;

    if (![defaults objectForKey:UseLargeTitlesOnRootListKey]) [defaults setBool:YES forKey:UseLargeTitlesOnRootListKey];
    if (![defaults objectForKey:AlwaysShowSearchBarKey]) [defaults setBool:NO forKey:AlwaysShowSearchBarKey];
    if (![defaults objectForKey:RequireActionConfirmationKey]) [defaults setBool:YES forKey:RequireActionConfirmationKey];
    if (![defaults objectForKey:LongPressOpensSettingsKey]) [defaults setBool:YES forKey:LongPressOpensSettingsKey];
}

@end