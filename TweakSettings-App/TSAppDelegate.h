//
//  AppDelegate.h
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <UIKit/UIKit.h>
#import "TSUtilityActionManager.h"

@class TSRootNavigationManager;

#define APP_DELEGATE ((TSAppDelegate *) UIApplication.sharedApplication.delegate)

@interface TSAppDelegate : UIApplication <UIApplicationDelegate>

@property(strong, nonatomic) UIWindow *window;
@property(nonatomic, weak) id popoverSender;
@property(nonatomic, strong, readonly) TSRootNavigationManager *navigationManager;

- (void)presentAsPopover:(UIViewController *)controller withSender:(id)sender;
- (void)presentViewController:(UIViewController *)controller;

- (void)handleActionForType:(NSString *)actionType;
- (void)openApplicationURL:(NSURL *)url;

- (void)generateURL;

@end
