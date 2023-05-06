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
#import "rootless.h"


int main(int argc, char *argv[]) {

    NSString *appDelegateClassName;

    @autoreleasepool {

        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([TSAppDelegate class]);

        NSArray *librariesToLoad = ARRAY_WITH_PLIST(ROOT_PATH_NS(@"/Applications/TweakSettings.app/libraries.plist"));

        for (NSString *path in librariesToLoad) {
            dlopen(ROOT_PATH_NS_VAR(path).UTF8String, RTLD_NOW);
        }

    }

    return UIApplicationMain(argc, argv, appDelegateClassName, appDelegateClassName);

}
