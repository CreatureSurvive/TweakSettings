#import <UIKit/UINavigationController.h>

@class PSListController;
@class PSViewController;

@interface PSRootController : UINavigationController

- (instancetype)initWithTitle:(NSString *)title identifier:(NSString *)identifier;

- (void)handleURL:(id)url ;
- (void)pushController:(PSViewController *)controller; // < 3.2
- (void)suspend;
- (void)setSupportedInterfaceOrientations:(NSUInteger)orientations;

@end
