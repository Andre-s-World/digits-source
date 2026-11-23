#import "DigitsApplicationOperations.h"

@implementation DigitsApplicationOperations (Maintenance)
- (void)runMaintenanceAction:(NSString *)action argument:(NSString *)argument
                 completion:(DigitsActionCompletion)completion {
    if (self.maintenanceRunning) {
        completion(NO, @"Another Digits change is still running.");
        return;
    }
    NSString *tool = [NSBundle.mainBundle.bundlePath
        stringByAppendingPathComponent:@"Contents/Library/Helpers/digits-maintenance"];
    if (![NSFileManager.defaultManager isExecutableFileAtPath:tool]) {
        completion(NO, @"Digits is missing its maintenance tool. Nothing changed.");
        return;
    }
    self.maintenanceRunning = YES;
    if (self.statusUpdate)
        self.statusUpdate([action isEqualToString:@"--uninstall"] ?
            @"Digits Touch removal accepted. Removing files and requesting startup-cache authorization…" :
            @"Saving the display binding and requesting the startup-cache update…");
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        // AppleScript's quoted form quotes each argument independently. User
        // display names never enter a shell command; only a validated UUID does.
        NSString *script = @"on run arguments\n"
            "set commandText to quoted form of (item 1 of arguments) & space & quoted form of (item 2 of arguments)\n"
            "if (count of arguments) is 3 then set commandText to commandText & space & quoted form of (item 3 of arguments)\n"
            "do shell script commandText with administrator privileges\n"
            "end run";
        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/osascript"];
        NSMutableArray *arguments = [NSMutableArray arrayWithArray:@[@"-e", script, @"--", tool, action]];
        if (argument.length)
            [arguments addObject:argument];
        task.arguments = arguments;
        NSPipe *pipe = [NSPipe pipe];
        task.standardOutput = pipe;
        task.standardError = pipe;
        NSError *launchError = nil;
        BOOL launched = [task launchAndReturnError:&launchError];
        NSData *data = launched ? [pipe.fileHandleForReading readDataToEndOfFile] : nil;
        if (launched)
            [task waitUntilExit];
        NSString *text = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
        NSDictionary *result = DigitsDecodeMaintenanceResult(text);
        BOOL succeeded = launched && task.terminationStatus == 0 && [result[@"success"] boolValue];
        NSString *message = result[@"message"] ?: text ?: launchError.localizedDescription ?: @"The change did not complete.";
        dispatch_async(dispatch_get_main_queue(), ^{
            self.maintenanceRunning = NO;
            completion(succeeded, message);
        });
    });
}
@end
