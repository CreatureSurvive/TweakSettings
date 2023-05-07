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
#import "rootless.h"
#import "NSTask.h"

NSString *const TSActionTypeRespring = @"respring";
NSString *const TSActionTypeSafemode = @"safemode";
NSString *const TSActionTypeUICache = @"uicache";
NSString *const TSActionTypeLDRestart = @"ldrestart";
NSString *const TSActionTypeReboot = @"reboot";
NSString *const TSActionTypeUserspaceReboot = @"usreboot";
NSString *const TSActionTypeTweakInject = @"tweakinject";

struct TaskResult ExecuteCommand(NSString *command) {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:ROOT_PATH_NS(@"/bin/sh")];
    [task setArguments:@[@"-c", command]];

    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput:outputPipe];

    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];

    [task launch];
    [task waitUntilExit];

    NSData *errorData;
    NSData *outputData;
    NSString *output;
    NSString *error;

    if (@available(iOS 13.0, *)) {
        outputData = [[[task standardOutput] fileHandleForReading] readDataToEndOfFileAndReturnError:nil];
        errorData = [[[task standardError] fileHandleForReading] readDataToEndOfFileAndReturnError:nil];
    } else {
        outputData = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
        errorData = [[[task standardError] fileHandleForReading] readDataToEndOfFile];
    }

    if (outputData && outputData.length > 0) {
        output =  [[NSString alloc] initWithData:outputData encoding:NSASCIIStringEncoding];
    }

    if (errorData && errorData.length > 0) {
        error = [[NSString alloc] initWithData:errorData encoding:NSASCIIStringEncoding];
        Error("TASK INPUT: %@ ERROR: %@, STATUS: %d", task.arguments.lastObject, error, task.terminationStatus)
    }

    struct TaskResult result;
    result.status = task.terminationStatus;
    result.output = output;
    result.error = error;

    return result;
}

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

BOOL CanRunWithoutConfirmation(NSString *actionType) {

    if (!actionType || !actionType.length) return NO;
    return !([actionType isEqualToString:TSActionTypeReboot]
        || [actionType isEqualToString:TSActionTypeLDRestart]
        || [actionType isEqualToString:TSActionTypeUserspaceReboot]);
};

int HandleActionForType(NSString *actionType) {

    if (!actionType || !actionType.length) return EXIT_FAILURE;

    NSString *command = CommandForActionType(actionType);
    Log("Will execute command: %@", command);
    struct TaskResult result = ExecuteCommand(command);

    if (result.status != 0) {
        Error("TaskResult (E: %@ O: %@ S: %d)", result.error, result.output, result.status);
    }

    return result.status;
}

UIAlertController *ActionAlertForType(NSString *actionType) {

    NSString *title = TitleForActionType(actionType);
    NSString *message = [NSString stringWithFormat:NSLocalizedString(ALERT_ACTION_MESSAGE_KEY, nil), SubtitleForActionType(actionType)];
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];

    [controller addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        HandleActionForType(actionType);
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(ALERT_CANCEL_TITLE_KEY, nil) style:UIAlertActionStyleCancel handler:nil]];

    return controller;
}

UIAlertController *ActionListAlert(void) {

    BOOL userspace_supported = access(ROOT_PATH("/odyssey/jailbreakd.plist"), F_OK) == 0 || access(ROOT_PATH("/taurine/jailbreakd.plist"), F_OK) == 0;
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(RESPRING_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeRespring];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(SAFEMODE_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeSafemode];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(UICACHE_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeUICache];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(LDRESTART_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeLDRestart];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(REBOOT_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeReboot];
    }]];
    if (userspace_supported) {
        [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(USREBOOT_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [APP_DELEGATE handleActionForType:TSActionTypeUserspaceReboot];
        }]];
    }
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(TWEAKINJECT_TITLE_KEY, nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeTweakInject];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(ALERT_CANCEL_TITLE_KEY, nil) style:UIAlertActionStyleCancel handler:nil]];

    return controller;
}

UIMenu *ActionListMenu(void) API_AVAILABLE(ios(13.0)) {

    NSMutableArray *menuActions = [NSMutableArray new];
    BOOL userspace_supported =
            access(ROOT_PATH("/odyssey/jailbreakd.plist"), F_OK) == 0 ||
            access(ROOT_PATH("/taurine/jailbreakd.plist"), F_OK) == 0 ||
            access(ROOT_PATH("/.installed_dopamine"), F_OK) == 0;

    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(RESPRING_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeRespring];
    }]];
    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(SAFEMODE_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeSafemode];
    }]];
    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(UICACHE_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeUICache];
    }]];
    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(LDRESTART_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeLDRestart];
    }]];
    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(REBOOT_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeReboot];
    }]];
    if (userspace_supported) {
        [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(USREBOOT_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
            [APP_DELEGATE handleActionForType:TSActionTypeUserspaceReboot];
        }]];
    }
    [menuActions addObject:[UIAction actionWithTitle:NSLocalizedString(TWEAKINJECT_TITLE_KEY, nil) image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [APP_DELEGATE handleActionForType:TSActionTypeTweakInject];
    }]];

    return [UIMenu menuWithTitle:@"" children:menuActions];
}

NSString *CommandForActionType(NSString *actionType) {
    return [NSString stringWithFormat:ROOT_PATH_NS(@"/usr/bin/tweaksettings-utility --%@"), actionType];
}