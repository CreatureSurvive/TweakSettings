//
//  AppDelegate.h
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <UIKit/UIKit.h>
#import "TSUtilityActionManager.h"

@interface TSAppDelegate : UIApplication <UIApplicationDelegate>

@property(strong, nonatomic) UIWindow *window;

- (void)handleActionForType:(NSString *)actionType withConfirmationSender:(id)sender;
- (void)openApplicationURL:(NSURL *)url;

@end
