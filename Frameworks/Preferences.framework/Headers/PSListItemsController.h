#import <UIKit/UIViewController.h>
#import <Preferences/PSListController.h>

@class PSSpecifier;

@interface PSListItemsController : PSListController {

        long long _rowToSelect;
        BOOL _deferItemSelection;
        BOOL _restrictionList;
        PSSpecifier* _lastSelectedSpecifier;
        id _retainedTarget;

}
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2;
- (id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2;
- (void)suspend;
- (void)viewWillAppear:(BOOL)arg1;
- (void)viewWillDisappear:(BOOL)arg1;
- (void)prepareSpecifiersMetadata;
- (void)didLock;
- (void)scrollToSelectedCell;
- (void)setValueForSpecifier:(id)arg1 defaultValue:(id)arg2;
- (void)setRowToSelect;
- (void)listItemSelected:(id)arg1;
- (void)_addStaticText:(id)arg1;
- (id)itemsFromParent;
- (NSMutableArray *)itemsFromDataSource;
- (BOOL)isRestrictionList;
- (void)setIsRestrictionList:(BOOL)arg1;
- (id)specifiers;
@end
