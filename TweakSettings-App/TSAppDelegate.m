//
//  AppDelegate.m
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <Preferences/PSRootController.h>
#import "TSAppDelegate.h"
#import "TSRootListController.h"
#import "Localizable.h"

void HandleExceptions(NSException *exception) {
    NSLog(@"unhandled exception: %@", [exception debugDescription]);
}

@interface TSAppDelegate ()

@property(nonatomic, strong) PSRootController *rootController;
@property(nonatomic, strong) TSRootListController *rootListController;

@end

@implementation TSAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    NSSetUncaughtExceptionHandler(&HandleExceptions);

    application.shortcutItems = @[
            [[UIApplicationShortcutItem alloc] initWithType:TSActionTypeTweakInject localizedTitle:NSLocalizedString(TWEAKINJECT_TITLE_KEY, nil) localizedSubtitle:NSLocalizedString(TWEAKINJECT_SUBTITLE_KEY, nil) icon:nil userInfo:nil],
            [[UIApplicationShortcutItem alloc] initWithType:TSActionTypeUICache localizedTitle:NSLocalizedString(UICACHE_TITLE_KEY, nil) localizedSubtitle:NSLocalizedString(UICACHE_SUBTITLE_KEY, nil) icon:nil userInfo:nil],
            [[UIApplicationShortcutItem alloc] initWithType:TSActionTypeSafemode localizedTitle:NSLocalizedString(SAFEMODE_TITLE_KEY, nil) localizedSubtitle:NSLocalizedString(SAFEMODE_SUBTITLE_KEY, nil) icon:nil userInfo:nil],
            [[UIApplicationShortcutItem alloc] initWithType:TSActionTypeRespring localizedTitle:NSLocalizedString(RESPRING_TITLE_KEY, nil) localizedSubtitle:NSLocalizedString(RESPRING_SUBTITLE_KEY, nil) icon:nil userInfo:nil]
    ];

    _rootListController = [TSRootListController new];
    _rootController = [[PSRootController alloc] initWithRootViewController:_rootListController];

    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = _rootController;
    [self.window makeKeyAndVisible];

    if (launchOptions[UIApplicationLaunchOptionsShortcutItemKey]) {

        [self handleActionForType:[(UIApplicationShortcutItem *)launchOptions[UIApplicationLaunchOptionsShortcutItemKey] type] withConfirmationSender:nil];
        return NO;
    }

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {

    if ([url.scheme isEqualToString:@"tweaks:"]) {
        [_rootController handleURL:url];
        return YES;
    }

    return NO;
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {

    [self handleActionForType:shortcutItem.type withConfirmationSender:nil];
    completionHandler(YES);
}

- (void)handleActionForType:(NSString *)actionType withConfirmationSender:(id)sender {

    UIAlertController *controller = ActionAlertForType(actionType);
    controller.modalPresentationStyle = UIModalPresentationPopover;

    if (sender && [sender isKindOfClass:UIBarButtonItem.class]) {

        controller.popoverPresentationController.barButtonItem = sender;

    } else if (sender && [sender isKindOfClass:UIView.class]) {

        controller.popoverPresentationController.sourceView = (UIView *)sender;
        controller.popoverPresentationController.sourceRect = ((UIView *)sender).bounds;

    } else {

        controller.popoverPresentationController.sourceView = self.rootController.view;
        controller.popoverPresentationController.sourceRect = self.rootController.view.bounds;
    }

    [self.rootController presentViewController:controller animated:YES completion:nil];
}

@end
