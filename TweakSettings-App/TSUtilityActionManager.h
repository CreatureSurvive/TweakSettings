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

extern inline NSString *TitleForActionType(NSString *type);
extern inline NSString *SubtitleForActionType(NSString *type);
extern inline int HandleActionForType(NSString *actionType);
extern inline UIAlertController *ActionAlertForType(NSString *actionType);
extern inline UIAlertController *ActionListAlert(id sender);
extern inline UIMenu *ActionListMenu(id sender) API_AVAILABLE(ios(13.0));

#endif /* TSActionType_h */
