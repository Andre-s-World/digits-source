#import "DigitsInstallerInternal.h"

@implementation DigitsInstallerBackend (RunHost)
- (void)runHostMode:(NSString *)mode completion:(DigitsInstallerCompletion)completion {
    [self performOperation:[mode isEqual:@"--installer-activate-touch"] ?
        @"Waiting for macOS to enable Digits Touch…" : @"Waiting for macOS to remove Digits Touch…"
        worker:^NSDictionary *{
            NSError *error = nil;
            NSString *path = @"/Applications/Digits.app";
            if (!DigitsInstallerVerifyCode(path, DIGITS_HOST_IDENTIFIER, &error))
                return DigitsInstallerResult(NO, error.localizedDescription);
            NSBundle *host = [NSBundle bundleWithPath:path];
            NSTask *task = [NSTask new];
            task.executableURL = host.executableURL;
            task.arguments = @[mode];
            NSPipe *output = [NSPipe pipe];
            NSPipe *errors = [NSPipe pipe];
            task.standardOutput = output;
            task.standardError = errors;
            if (![task launchAndReturnError:&error])
                return DigitsInstallerResult(NO, error.localizedDescription);
            NSMutableData *pending = [NSMutableData new];
            __block NSDictionary *terminal = nil;
            while (YES) {
                NSData *chunk = [output.fileHandleForReading availableData];
                if (!chunk.length)
                    break;
                [pending appendData:chunk];
                while (YES) {
                    const uint8_t *bytes = pending.bytes;
                    NSUInteger length = pending.length;
                    NSUInteger newline = 0;
                    while (newline < length && bytes[newline] != '\n')
                        ++newline;
                    if (newline == length)
                        break;
                    NSData *line = [pending subdataWithRange:NSMakeRange(0, newline)];
                    [pending replaceBytesInRange:NSMakeRange(0, newline + 1) withBytes:NULL length:0];
                    id decoded = [NSJSONSerialization JSONObjectWithData:line options:0 error:NULL];
                    NSDictionary *event = [decoded isKindOfClass:NSDictionary.class] ? decoded : nil;
                    NSString *kind = event[@"event"];
                    NSString *message = [event[@"message"] isKindOfClass:NSString.class] ? event[@"message"] : nil;
                    if ([kind isEqual:@"needsApproval"]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (self.statusUpdate)
                                self.statusUpdate(message ?: @"Approve Digits Touch in System Settings, then return here.");
                        });
                    } else if ([kind isEqual:@"complete"] || [kind isEqual:@"failed"]) {
                        terminal = event;
                    }
                }
            }
            [task waitUntilExit];
            NSData *errorData = [errors.fileHandleForReading readDataToEndOfFile];
            NSString *diagnostic = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
            BOOL succeeded = task.terminationStatus == 0 && [terminal[@"event"] isEqual:@"complete"] &&
                [terminal[@"approved"] boolValue];
            NSString *message = terminal[@"message"] ?: diagnostic;
            if (!message.length)
                message = @"macOS did not confirm the Digits Touch request.";
            if (succeeded && [terminal[@"restartRequired"] boolValue])
                message = [message stringByAppendingString:@" Its final state will take effect after the final restart."];
            return DigitsInstallerResult(succeeded, message);
        } completion:completion];
}
@end
