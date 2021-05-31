//
//  TSActionType.m
//  TweakSettings
//
//  Created by Dana Buehre on 5/30/21.
//
//

#import <UIKit/UIKit.h>
#import "TSUtilityActionManager.h"
#import "Localizable.h"
#import "TSAppDelegate.h"

NSString *const TSActionTypeRespring = @"respring";
NSString *const TSActionTypeSafemode = @"safemode";
NSString *const TSActionTypeUICache = @"uicache";
NSString *const TSActionTypeLDRestart = @"ldrestart";
NSString *const TSActionTypeReboot = @"reboot";
NSString *const TSActionTypeUserspaceReboot = @"usreboot";
NSString *const TSActionTypeTweakInject = @"tweakinject";

NSString *TitleForActionType(NSString *type) {
    if ([type isEqualToString:TSActionTypeRespring]) return NSLocalizedString(RESPRING_TITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeSafemode]) return NSLocalizedString(SAFEMODE_TITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeUICache]) return NSLocalizedString(UICACHE_TITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeLDRestart]) return NSLocalizedString(LDRESTART_TITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeReboot]) return NSLocalizedString(REBOOT_TITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeUserspaceReboot]) return NSLocalizedString(USREBOOT_TITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeTweakInject]) return NSLocalizedString(TWEAKINJECT_TITLE_KEY, nil);
    return nil;
}

NSString *SubtitleForActionType(NSString *type) {
    if ([type isEqualToString:TSActionTypeRespring]) return NSLocalizedString(RESPRING_SUBTITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeSafemode]) return NSLocalizedString(SAFEMODE_SUBTITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeUICache]) return NSLocalizedString(UICACHE_SUBTITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeLDRestart]) return NSLocalizedString(LDRESTART_SUBTITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeReboot]) return NSLocalizedString(REBOOT_SUBTITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeUserspaceReboot]) return NSLocalizedString(USREBOOT_SUBTITLE_KEY, nil);
    if ([type isEqualToString:TSActionTypeTweakInject]) return NSLocalizedString(TWEAKINJECT_SUBTITLE_KEY, nil);
    return nil;
}

int HandleActionForType(NSString *actionType) {

    if (!actionType || !actionType.length) return EXIT_FAILURE;

    int status = STATUS_FOR_COMMAND([NSString stringWithFormat:@"/usr/bin/tweaksettings-utility --%@", actionType]);
    if (status == EXIT_SUCCESS && [actionType isEqualToString:TSActionTypeTweakInject]) {
        if (access("/etc/rc.d/substrate", F_OK) == 0) {
            if (STATUS_FOR_COMMAND(@"/usr/bin/tweaksettings-utility --substrated") == EXIT_SUCCESS) {
                STATUS_FOR_COMMAND(@"/usr/bin/tweaksettings-utility --respring");
            }
        } else {
            STATUS_FOR_COMMAND(@"/usr/bin/tweaksettings-utility --respring");
        }
    }

    return status;
}

UIAlertController *ActionAlertForType(NSString *actionType) {

    NSString *title = TitleForActionType(actionType);
    NSString *message = [NSString stringWithFormat:NSLocalizedString(ALERT_ACTION_MESSAGE_KEY, nil), SubtitleForActionType(actionType)];
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];

    [controller addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        HandleActionForType(actionType);
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(ALERT_CANCEL_TITLE_KEY, nil) style:UIAlertActionStyleCancel handler:nil]];

    return controller;
}

UIAlertController *ActionListAlert(id sender) {

    BOOL userspace_supported = access("/odyssey/jailbreakd.plist", F_OK) == 0 || access("/taurine/jailbreakd.plist", F_OK) == 0;
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    controller.modalPresentationStyle = UIModalPresentationPopover;
    controller.popoverPresentationController.barButtonItem = sender;

    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(RESPRING_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeRespring withConfirmationSender:sender];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(SAFEMODE_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeSafemode withConfirmationSender:sender];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(UICACHE_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeUICache withConfirmationSender:sender];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(LDRESTART_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeLDRestart withConfirmationSender:sender];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(REBOOT_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeReboot withConfirmationSender:sender];
    }]];
    if (userspace_supported) {
        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(USREBOOT_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeUserspaceReboot withConfirmationSender:sender];
        }]];
    }
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(TWEAKINJECT_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeTweakInject withConfirmationSender:sender];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(ALERT_CANCEL_TITLE_KEY, nil) style:UIAlertActionStyleCancel handler:nil]];

    return controller;
}

UIMenu *ActionListMenu(id sender) API_AVAILABLE(ios(13.0)) {

    NSMutableArray *menuActions = [NSMutableArray new];
    BOOL userspace_supported = access("/odyssey/jailbreakd.plist", F_OK) == 0 || access("/taurine/jailbreakd.plist", F_OK) == 0;

    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(RESPRING_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeRespring withConfirmationSender:sender];
    }]];
    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(SAFEMODE_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeSafemode withConfirmationSender:sender];
    }]];
    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(UICACHE_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeUICache withConfirmationSender:sender];
    }]];
    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(LDRESTART_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeLDRestart withConfirmationSender:sender];
    }]];
    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(REBOOT_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeReboot withConfirmationSender:sender];
    }]];
    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(USREBOOT_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeUserspaceReboot withConfirmationSender:sender];
    }]];
    if (userspace_supported) {
        [UIAction actionWithTitle:NSLocalizedString(USREBOOT_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
            [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeUserspaceReboot withConfirmationSender:sender];
        }];
    }
    [UIAction actionWithTitle:NSLocalizedString(TWEAKINJECT_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [((TSAppDelegate *)UIApplication.sharedApplication) handleActionForType:TSActionTypeTweakInject withConfirmationSender:sender];
    }];

    return [UIMenu menuWithTitle:@"" children:menuActions];
}