@class PSListController;

@interface PSRootController : UINavigationController

- (instancetype)initWithTitle:(NSString *)title identifier:(NSString *)identifier;

- (void)handleURL:(id)url ;
- (void)pushController:(PSListController *)controller; // < 3.2
- (void)suspend;

@end
