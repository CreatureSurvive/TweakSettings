#import <Preferences/PSListController.h>

@interface PSEditableListController : PSListController {

	BOOL _editable;
	BOOL _editingDisabled;

}
- (id)init;
- (id)tableView:(id)arg1 willSelectRowAtIndexPath:(id)arg2 ;
- (UITableViewCellEditingStyle)tableView:(id)arg1 editingStyleForRowAtIndexPath:(id)arg2 ;
- (void)tableView:(id)arg1 commitEditingStyle:(long long)arg2 forRowAtIndexPath:(id)arg3 ;
- (void)suspend;
- (void)viewWillAppear:(BOOL)arg1 ;
- (void)setEditable:(BOOL)arg1 ;
- (BOOL)editable;
- (void)showController:(id)arg1 animate:(BOOL)arg2 ;
- (void)didLock;
- (void)editDoneTapped;
- (id)_editButtonBarItem;
- (void)_setEditable:(BOOL)arg1 animated:(BOOL)arg2 ;
- (BOOL)performDeletionActionForSpecifier:(id)arg1 ;
- (void)setEditingButtonHidden:(BOOL)arg1 animated:(BOOL)arg2 ;
- (void)setEditButtonEnabled:(BOOL)arg1 ;
- (void)_updateNavigationBar;
@end

