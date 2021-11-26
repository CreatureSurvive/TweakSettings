//
// Created by Dana Buehre on 11/13/21.
//

#import <Foundation/Foundation.h>


static NSString *const TSUserDefaultsChangedKey = @"@kTSUserDefaultsChanged";
static NSString *const UseLargeTitlesOnRootListKey = @"kUseLargeTitlesOnRootList";
static NSString *const AlwaysShowSearchBarKey = @"kAlwaysShowSearchBar";
static NSString *const RequireActionConfirmationKey = @"kRequireActionConfirmation";
static NSString *const LongPressOpensSettingsKey = @"kLongPressOpensSettings";

@interface TSUserDefaults : NSObject

@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, readwrite) BOOL useLargeTitlesOnRootList;
@property (nonatomic, readwrite) BOOL alwaysShowSearchBar;
@property (nonatomic, readwrite) BOOL requireActionConfirmation;
@property (nonatomic, readwrite) BOOL longPressOpensSettings;

+ (instancetype)sharedDefaults;
@end