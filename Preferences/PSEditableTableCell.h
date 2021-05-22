#import "PSTableCell.h"

@class PSSpecifier;
@interface PSEditableTableCell : PSTableCell {
	id _userInfo;
	SEL _targetSetter;
	id _realTarget;
}

- (void)controlChanged:(id)changed;
- (void)setValueChangedOnReturn;
- (void)setValueChangedTarget:(id)target action:(SEL)action userInfo:(id)info;

- (void)setValue:(id)arg1;
- (void)setValueChangedTarget:(id)arg1 action:(SEL)arg2 specifier:(PSSpecifier *)arg3;
- (UITextField *)textField;
- (void)textFieldDidBeginEditing:(id)arg1;
- (void)textFieldDidEndEditing:(id)arg1;
- (bool)textFieldShouldClear:(id)arg1;
- (bool)textFieldShouldReturn:(id)arg1;
- (id)value;


@end
