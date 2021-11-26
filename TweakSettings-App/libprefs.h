//
//  libprefs.h
//  TweakSettings
//
// Created by Dana Buehre on 5/22/21.
//

#ifndef TS_LIBPREFS_H
#define TS_LIBPREFS_H

@interface PSListController (libprefs)
- (NSArray *)specifiersFromEntry:(NSDictionary *)entry sourcePreferenceLoaderBundlePath:(NSString *)sourceBundlePath title:(NSString *)title;
- (PSViewController *)controllerForSpecifier:(PSSpecifier *)specifier;
@end

@interface PSSpecifier (libprefs)
+ (BOOL)environmentPassesPreferenceLoaderFilter:(NSDictionary *)filter;
@end

#endif //TS_LIBPREFS_H
