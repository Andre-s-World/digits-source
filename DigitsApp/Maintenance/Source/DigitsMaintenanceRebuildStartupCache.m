#import "DigitsMaintenance.h"
#import <pwd.h>
#import <sys/stat.h>

BOOL DigitsMaintenanceRebuildStartupCache(NSString **output, NSError **error) {
    struct stat consoleStatus;
    struct passwd *consoleAccount = NULL;
    if (stat("/dev/console", &consoleStatus) == 0)
        consoleAccount = getpwuid(consoleStatus.st_uid);
    NSString *consoleName = consoleAccount ? [NSString stringWithUTF8String:consoleAccount->pw_name] : nil;
    if (!consoleAccount || consoleStatus.st_uid == 0 || !consoleName.length ||
        [@[@"root", @"loginwindow", @"_mbsetupuser", @"nobody"] containsObject:consoleName]) {
        NSString *message = @"No active signed-in desktop session was found. Sign in at this Mac and retry; the startup cache was not rebuilt.";
        if (output)
            *output = message;
        if (error)
            *error = DigitsMaintenanceError(message);
        return NO;
    }
    NSString *consoleUID = [NSString stringWithFormat:@"%u", (unsigned int)consoleStatus.st_uid];
    // asuser selects the desktop bootstrap without dropping root. A fresh
    // helper session supplies the account login name used by kmutil, while
    // macOS itself still requests and validates owner authorization.
    NSTask *task = [NSTask new];
    task.executableURL = [NSURL fileURLWithPath:@"/bin/launchctl"];
    task.arguments = @[@"asuser", consoleUID, NSProcessInfo.processInfo.arguments.firstObject,
            @"--startup-cache-session"];
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    NSError *launchError = nil;
    if (![task launchAndReturnError:&launchError]) {
        NSString *message = [NSString stringWithFormat:@"The startup-cache authorization request could not start. %@",
            launchError.localizedDescription ?: @"Unknown launch failure."];
        if (output)
            *output = message;
        if (error)
            *error = DigitsMaintenanceError(message);
        return NO;
    }
    NSData *data = [pipe.fileHandleForReading readDataToEndOfFile];
    [task waitUntilExit];
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
    if (output)
        *output = text;
    int status = task.terminationStatus;
    if (status == 0 && task.terminationReason == NSTaskTerminationReasonExit)
        return YES;
    NSString *guidance = @"The startup-cache update did not complete. Complete any authorization macOS presents, then retry this operation.";
    if (status == 254 || [text.lowercaseString containsString:@"authentication canceled"] ||
        [text.lowercaseString containsString:@"authentication cancelled"]) {
        guidance = @"Startup-cache authorization was cancelled. Removal is not complete and Digits was kept. Retry this operation when ready and approve the password prompt for your signed-in Mac account. Do not enable or enter a password for the root account.";
    } else if (status == 27) {
        guidance = @"macOS still requires startup-cache approval. Retry this operation and complete the macOS password prompt for your signed-in account. The administrator password used to start this operation is separate from startup-cache authorization. Retry this operation before the final restart.";
    } else if (status == 28) {
        guidance = @"macOS reports that the startup-cache request requires a restart. This operation is not confirmed complete. Finish all remaining approval and password steps before taking the final restart.";
    } else if (status == 71 || [text.lowercaseString containsString:@"timedout"] ||
               [text.lowercaseString containsString:@"timed out"]) {
        guidance = @"macOS did not complete startup-cache authorization. Retry this operation and complete the macOS password prompt for your signed-in account. The administrator password used to start this operation is separate from startup-cache authorization.";
    }
    if (error)
        *error = DigitsMaintenanceError([NSString stringWithFormat:@"%@ Exit status: %d. Details: %@", guidance, status, text]);
    return NO;
}
