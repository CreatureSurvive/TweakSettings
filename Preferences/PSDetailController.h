#import "PSViewController.h"

@class UIKeyboard, PSEditingPane, UIView;

@interface PSDetailController : PSViewController {
	PSEditingPane* _pane;
	UIKeyboard* _keyboard;
	BOOL _keyboardVisible;
}

@property(retain) PSEditingPane *pane;
@property(readonly, assign) BOOL keyboardVisible;

- (void)_updateNavBarButtons;
- (void)_addKeyboardView;
- (void)setKeyboardVisible:(BOOL)visible animated:(BOOL)animated;
- (void)saveChanges;
- (void)doneButtonClicked:(id)clicked;
- (void)cancelButtonClicked:(id)clicked;
@end
