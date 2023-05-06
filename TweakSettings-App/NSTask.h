#import <Foundation/NSObject.h>

@class NSString, NSArray, NSDictionary;

@interface NSTask : NSObject

// Create an NSTask which can be run at a later time
// An NSTask can only be run once. Subsequent attempts to
// run an NSTask will raise.
// Upon task death a notification will be sent
//   { Name = NSTaskDidTerminateNotification; object = task; }
//

- (_Nullable instancetype)init;

// set parameters
// these methods can only be done before a launch
// if not set, use current
// if not set, use current

// set standard I/O channels; may be either an NSFileHandle or an NSPipe
- (void)setStandardInput:(id _Nullable)input;
- (void)setStandardOutput:(id _Nullable)output;
- (void)setStandardError:(id _Nullable)error;

// get parameters
@property (NS_NONATOMIC_IOSONLY, copy) NSString *_Nullable launchPath;
@property (NS_NONATOMIC_IOSONLY, copy) NSArray *_Nullable arguments;
@property (NS_NONATOMIC_IOSONLY, copy) NSDictionary *_Nullable environment;
@property (NS_NONATOMIC_IOSONLY, copy) NSString *_Nullable currentDirectoryPath;
@property(NS_NONATOMIC_IOSONLY, copy) NSURL *_Nullable currentDirectoryURL;

// get standard I/O channels; could be either an NSFileHandle or an NSPipe
- (id _Nullable)standardInput;
- (id _Nullable)standardOutput;
- (id _Nullable)standardError;

// actions
- (void)launch;

- (void)interrupt; // Not always possible. Sends SIGINT.
- (void)terminate; // Not always possible. Sends SIGTERM.

@property (NS_NONATOMIC_IOSONLY, readonly) BOOL suspend;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL resume;

// status
@property (NS_NONATOMIC_IOSONLY, readonly) int processIdentifier;
@property (NS_NONATOMIC_IOSONLY, getter = isRunning, readonly) BOOL running;

@property (NS_NONATOMIC_IOSONLY, readonly) int terminationStatus;
@property (copy, nonnull) void (^terminationHandler)(NSTask *_Nonnull);

@end

@interface NSTask (NSTaskConveniences)

+ (NSTask *_Nullable)launchedTaskWithLaunchPath:(NSString *_Nonnull)path arguments:(NSArray *_Nullable)arguments;
// convenience; create and launch

- (void)waitUntilExit;
// poll the runLoop in defaultMode until task completes

@end

FOUNDATION_EXPORT NSString *_Nullable const NSTaskDidTerminateNotification;