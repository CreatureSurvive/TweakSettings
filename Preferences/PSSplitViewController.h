#import <UIKit/UISplitViewController.h>

@protocol PSSplitViewControllerNavigationDelegate <NSObject>
- (void)splitViewControllerDidPopToRootController:(id)splitViewController;
@end

@class PSRootController;

@interface PSSplitViewController : UISplitViewController

@property (nonatomic,retain) PSRootController * containerNavigationController;
@property (nonatomic, weak) id<PSSplitViewControllerNavigationDelegate> navigationDelegate;
- (void)setViewControllers:(id)arg1 ;
- (id)childViewControllerForStatusBarStyle;
- (id<PSSplitViewControllerNavigationDelegate>)navigationDelegate;
- (PSRootController *)containerNavigationController;
- (void)popRecursivelyToRootController;
- (id)categoryController;
- (void)showInitialViewController:(id)arg1 ;
- (void)setNavigationDelegate:(id<PSSplitViewControllerNavigationDelegate>)arg1 ;
- (void)setContainerNavigationController:(PSRootController *)arg1 ;
- (void)setupControllerForToolbar:(id)arg1 ;
- (NSUInteger)supportedInterfaceOrientations;
@end
