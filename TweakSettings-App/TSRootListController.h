//
//  TSRootListController.h
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import "TSSearchableListController.h"

@interface TSRootListController : TSSearchableListController

@property (nonatomic, strong) NSString *launchIdentifier;

- (void)pushToLaunchIdentifier;
@end
