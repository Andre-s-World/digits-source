#import "DigitsMaintenance.h"

BOOL DigitsMaintenanceRunCommand(NSString *executable, NSArray<NSString *> *arguments,
                                 NSString **output, NSError **error) {
    NSTask *task = [[NSTask alloc] init];
    task.executableURL = [NSURL fileURLWithPath:executable];
    task.arguments = arguments;
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    if (![task launchAndReturnError:error])
        return NO;
    NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
    [task waitUntilExit];
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
    if (output)
        *output = text;
    if (task.terminationStatus != 0 && task.terminationStatus != 27 && task.terminationStatus != 28) {
        *error = DigitsMaintenanceError([NSString stringWithFormat:@"%@ failed (%d). %@",
            executable.lastPathComponent, task.terminationStatus, text]);
        return NO;
    }
    return YES;
}
