#import "DigitsInstallerInternal.h"

NSDictionary *DigitsInstallerMaintenancePrepareRemovalHost(NSString *payloadDirectory) {
    NSError *error = nil;
    NSDictionary *manifest = DigitsInstallerVerifyPayloads(payloadDirectory, &error);
    if (!manifest || !DigitsInstallerMaintenanceValidateDestinations(&error))
        return DigitsInstallerResult(NO, error.localizedDescription);
    if ([manifest[@"appVersion"] compare:@"0.2.4" options:NSNumericSearch] == NSOrderedAscending)
        return DigitsInstallerResult(NO, @"This installer does not contain a Digits host with macOS removal support.");
    NSString *destination = @"/Applications/Digits.app";
    if (![NSFileManager.defaultManager fileExistsAtPath:destination])
        return DigitsInstallerResult(NO, @"The installed Digits host disappeared. Restart the uninstall check.");
    // The user requested full uninstall. Replace only its already-closed GUI
    // host so normal OS-managed deactivation can run; retain all configuration
    // and loaded driver state until that request has actually completed.
    if (![NSFileManager.defaultManager removeItemAtPath:destination error:&error])
        return DigitsInstallerResult(NO, error.localizedDescription);
    NSDictionary *copied = DigitsInstallerRunTask(@"/usr/bin/ditto",
        @[[payloadDirectory stringByAppendingPathComponent:@"Digits.app"], destination]);
    if ([copied[@"exitStatus"] intValue] != 0)
        return DigitsInstallerResult(NO, [@"Removal support could not be copied. Driver and settings were kept. "
            stringByAppendingString:copied[@"output"]]);
    NSDictionary *ownership = DigitsInstallerRunTask(@"/usr/sbin/chown", @[@"-R", @"root:wheel", destination]);
    NSDictionary *permissions = DigitsInstallerRunTask(@"/bin/chmod", @[@"-R", @"go-w", destination]);
    if ([ownership[@"exitStatus"] intValue] != 0 || [permissions[@"exitStatus"] intValue] != 0 ||
        !DigitsInstallerVerifyCode(destination, DIGITS_HOST_IDENTIFIER, &error))
        return DigitsInstallerResult(NO, error.localizedDescription ?:
            @"Removal support was copied, but its signature or permissions could not be verified. Driver and settings were kept.");
    return DigitsInstallerResult(YES, @"Verified macOS removal support is ready. Driver and settings are unchanged.");
}
