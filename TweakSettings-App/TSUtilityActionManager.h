//
//  TSActionType.h
//  TweakSettings
//
//  Created by Dana Buehre on 5/30/21.
//
//

#ifndef TSActionType_h
#define TSActionType_h

@class UIAlertController;
@class UIAlertAction;

extern NSString *const TSActionTypeRespring;
extern NSString *const TSActionTypeSafemode;
extern NSString *const TSActionTypeUICache;
extern NSString *const TSActionTypeLDRestart;
extern NSString *const TSActionTypeReboot;
extern NSString *const TSActionTypeUserspaceReboot;
extern NSString *const TSActionTypeTweakInject;

extern NSString *TitleForActionType(NSString *type);
extern NSString *SubtitleForActionType(NSString *type);
extern BOOL CanRunWithoutConfirmation(NSString *actionType);
extern int HandleActionForType(NSString *actionType);
extern UIAlertController *ActionAlertForType(NSString *actionType);
extern UIAlertController *ActionListAlert(void);
extern UIMenu *ActionListMenu(void) API_AVAILABLE(ios(13.0));

#endif /* TSActionType_h */
