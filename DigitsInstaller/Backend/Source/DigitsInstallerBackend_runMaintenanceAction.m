#import "DigitsInstallerInternal.h"

@implementation DigitsInstallerBackend (RunMaintenance)
- (NSDictionary *)runMaintenanceAction:(NSString *)action argument:(NSString *)argument {
    NSString *tool = [NSBundle.mainBundle.bundlePath
        stringByAppendingPathComponent:@"Contents/Library/Helpers/digits-installer-maintenance"];
    if (![NSFileManager.defaultManager isExecutableFileAtPath:tool])
        return DigitsInstallerResult(NO, @"The installer is missing its maintenance tool.");
    // Arguments are passed separately to osascript and quoted there. No display
    // name, arbitrary command or externally supplied file path enters the shell.
    NSString *script = @"on run arguments\n"
        "set commandText to quoted form of (item 1 of arguments) & space & quoted form of (item 2 of arguments)\n"
        "if (count of arguments) is 3 then set commandText to commandText & space & quoted form of (item 3 of arguments)\n"
        "do shell script commandText with administrator privileges\n"
        "end run";
    NSMutableArray *arguments = [NSMutableArray arrayWithArray:@[@"-e", script, @"--", tool, action]];
    if (argument.length)
        [arguments addObject:argument];
    NSDictionary *task = DigitsInstallerRunTask(@"/usr/bin/osascript", arguments);
    // AppleScript wraps a failed privileged helper in an execution-error line.
    // Retain its structured message without treating a failed process as success.
    NSString *output = task[@"output"] ?: @"";
    NSRange firstBrace = [output rangeOfString:@"{"];
    NSRange lastBrace = [output rangeOfString:@"}" options:NSBackwardsSearch];
    NSDictionary *result = nil;
    if (firstBrace.location != NSNotFound && lastBrace.location != NSNotFound &&
        lastBrace.location >= firstBrace.location) {
        NSString *payload = [output substringWithRange:NSMakeRange(firstBrace.location,
            NSMaxRange(lastBrace) - firstBrace.location)];
        id decoded = [NSJSONSerialization JSONObjectWithData:
            [payload dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        if ([decoded isKindOfClass:NSDictionary.class] &&
            [decoded[@"success"] isKindOfClass:NSNumber.class] &&
            [decoded[@"message"] isKindOfClass:NSString.class])
            result = decoded;
    }
    if ([task[@"exitStatus"] intValue] != 0 || !result)
        return DigitsInstallerResult(NO, result[@"message"] ?: output);
    return result;
}
@end
