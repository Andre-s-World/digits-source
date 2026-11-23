#import "DigitsInstallerInternal.h"
#import <pwd.h>
#import <sys/stat.h>

NSDictionary *DigitsInstallerMaintenanceRebuildStartupCache(void) {
    struct stat consoleStatus;
    struct passwd *consoleAccount = NULL;
    if (stat("/dev/console", &consoleStatus) == 0)
        consoleAccount = getpwuid(consoleStatus.st_uid);
    NSString *consoleName = consoleAccount ? [NSString stringWithUTF8String:consoleAccount->pw_name] : nil;
    if (!consoleAccount || consoleStatus.st_uid == 0 || !consoleName.length ||
        [@[@"root", @"loginwindow", @"_mbsetupuser", @"nobody"] containsObject:consoleName]) {
        return @{@"exitStatus":@(-1), @"output":
            @"No active signed-in desktop session was found. Sign in at this Mac and retry; the startup cache was not rebuilt."};
    }
    NSString *consoleUID = [NSString stringWithFormat:@"%u", (unsigned int)consoleStatus.st_uid];
    // asuser selects the desktop bootstrap without dropping root. A fresh
    // helper session supplies the account login name used by kmutil, while
    // macOS itself still requests and validates owner authorization.
    NSDictionary *result = DigitsInstallerRunTask(@"/bin/launchctl",
        @[@"asuser", consoleUID, NSProcessInfo.processInfo.arguments.firstObject,
            @"--startup-cache-session"]);
    int status = [result[@"exitStatus"] intValue];
    if (status == 0)
        return result;
    NSString *text = result[@"output"] ?: @"";
    NSString *guidance = @"The startup-cache update did not complete. Complete any authorization macOS presents, then retry removal.";
    if (status == 254 || [text.lowercaseString containsString:@"authentication canceled"] ||
        [text.lowercaseString containsString:@"authentication cancelled"]) {
        guidance = @"Startup-cache authorization was cancelled. Removal is not complete. Retry from Digits Installer when ready and approve the password prompt for your signed-in Mac account. Do not enable or enter a password for the root account.";
    } else if (status == 27) {
        guidance = @"macOS still requires startup-cache approval. Retry this operation and complete the macOS password prompt for your signed-in account. The administrator password used to start this operation is separate from startup-cache authorization. Retry removal before the final restart.";
    } else if (status == 28) {
        guidance = @"macOS reports that the startup-cache request requires a restart. Removal is not confirmed complete. Finish all remaining approval and password steps before taking the final restart.";
    } else if (status == 71 || [text.lowercaseString containsString:@"timedout"] ||
               [text.lowercaseString containsString:@"timed out"]) {
        guidance = @"macOS did not complete startup-cache authorization. Retry removal and complete the macOS password prompt for your signed-in account. The administrator password used to start this operation is separate from startup-cache authorization.";
    }
    return @{@"exitStatus":result[@"exitStatus"] ?: @(-1), @"output":
        [NSString stringWithFormat:@"%@ Exit status: %d. Details: %@", guidance, status, text]};
}
