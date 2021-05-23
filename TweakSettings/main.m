//
//  main.m
//  TweakSettings
//
//  Created by Dana Buehre on 5/16/21.
//
//

#import <UIKit/UIKit.h>
#import <dlfcn.h>

#import "TSAppDelegate.h"


int main(int argc, char *argv[]) {

    NSString *appDelegateClassName;

    @autoreleasepool {

        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([TSAppDelegate class]);

        NSArray *librariesToLoad = ARRAY_WITH_PLIST(@"/Applications/TweakSettings.app/libraries.plist");

        for (NSString *path in librariesToLoad) {
            dlopen(path.UTF8String, RTLD_NOW);
        }

    }

    return UIApplicationMain(argc, argv, nil, appDelegateClassName);

}
