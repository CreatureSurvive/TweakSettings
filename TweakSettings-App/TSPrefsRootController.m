//
// Created by Dana Buehre on 11/6/21.
//

#import "TSPrefsRootController.h"
#import "TSRootListController.h"


@implementation TSPrefsRootController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController rootListController:(TSRootListController *)rootListController {
    if (self = [super initWithRootViewController:rootViewController]) {

        _rootListController = rootListController;
    }

    return self;
}

- (instancetype)initWithRootListController:(TSRootListController *)rootListController {
    if (self = [super init]) {

        _rootListController = rootListController;
    }

    return self;
}

@end