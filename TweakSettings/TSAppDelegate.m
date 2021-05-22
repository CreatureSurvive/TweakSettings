//
//  AppDelegate.m
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import "TSAppDelegate.h"
#import "TSRootListController.h"
#import "PSRootController.h"
#import "Localizable.h"

void HandleExceptions(NSException *exception)
{
    NSLog(@"unhandled exception: %@", [exception debugDescription]);
}

@interface TSAppDelegate ()

@property (nonatomic, strong) PSRootController *rootController;
@property (nonatomic, strong) TSRootListController *rootListController;

@end

@implementation TSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.

    NSSetUncaughtExceptionHandler(&HandleExceptions);
    
    application.shortcutItems = @[
            [[UIApplicationShortcutItem alloc] initWithType:@"respring" localizedTitle:NSLocalizedString(RESPRING_APPLICATION_TITLE, nil) localizedSubtitle:nil icon:nil userInfo: nil],
            [[UIApplicationShortcutItem alloc] initWithType:@"safemode" localizedTitle:NSLocalizedString(SAFEMODE_APPLICATION_TITLE, nil) localizedSubtitle:nil icon:nil userInfo:nil],
            [[UIApplicationShortcutItem alloc] initWithType:@"uicache" localizedTitle:NSLocalizedString(UICACHE_APPLICATION_TITLE, nil) localizedSubtitle:nil icon:nil userInfo:nil]
    ];

    _rootListController = [TSRootListController new];
    _rootController = [[PSRootController alloc] initWithRootViewController:_rootListController];

    self.window = [[UIWindow alloc] initWithFrame:UIScreen .mainScreen.bounds];
    self.window.rootViewController = _rootController;
    [self.window makeKeyAndVisible];

    if (launchOptions[UIApplicationLaunchOptionsShortcutItemKey]) {
        [self handleShortcutItemPressed:launchOptions[UIApplicationLaunchOptionsShortcutItemKey]];

        return NO;
    }

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
    if ([url.scheme isEqualToString:@"tweaks:"])
    {
        [_rootController handleURL:url];
        return YES;
    }

    return NO;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
    [self handleShortcutItemPressed:shortcutItem];

    completionHandler(YES);
}

- (void)handleShortcutItemPressed:(UIApplicationShortcutItem *)item
{
    if ([item.type isEqualToString:@"respring"])
    {
        STATUS_FOR_COMMAND(@"/usr/bin/killall backboardd");
    }
    else if ([item.type isEqualToString:@"safemode"])
    {
        STATUS_FOR_COMMAND(@"/usr/bin/killall -SEGV SpringBoard");
    }
    else if ([item.type isEqualToString:@"uicache"])
    {
        STATUS_FOR_COMMAND(@"/usr/bin/uicache");
    }
}

@end
