#import "DigitsInstallerInternal.h"

NSDictionary *DigitsInstallerRunTask(NSString *executable, NSArray<NSString *> *arguments) {
    NSTask *task = [NSTask new];
    task.executableURL = [NSURL fileURLWithPath:executable];
    task.arguments = arguments;
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    NSError *error = nil;
    if (![task launchAndReturnError:&error])
        return @{ @"exitStatus":@(-1), @"output":error.localizedDescription ?: @"Unable to launch command." };
    NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
    [task waitUntilExit];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
    return @{ @"exitStatus":@(task.terminationStatus), @"output":output };
}
