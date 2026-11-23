#import "DigitsInstallerInternal.h"

NSDictionary *DigitsInstallerMaintenanceInstallApp(NSString *uuid, BOOL reinstall, NSString *payloadDirectory) {
    NSError *error = nil;
    NSDictionary *manifest = DigitsInstallerVerifyPayloads(payloadDirectory, &error);
    NSUUID *identifier = [[NSUUID alloc] initWithUUIDString:uuid];
    if (!manifest || !identifier || [identifier.UUIDString isEqual:@"00000000-0000-0000-0000-000000000000"])
        return DigitsInstallerResult(NO, error.localizedDescription ?: @"The selected display UUID is invalid.");
    if (!DigitsInstallerMaintenanceValidateDestinations(&error))
        return DigitsInstallerResult(NO, error.localizedDescription);
    if (reinstall && !DigitsInstallerMaintenanceRemoveFiles(YES, &error))
        return DigitsInstallerResult(NO, [@"Reinstall cleanup did not complete. Some files may already have been removed. " stringByAppendingString:error.localizedDescription]);
    NSString *source = [payloadDirectory stringByAppendingPathComponent:@"Digits.app"];
    NSString *destination = @"/Applications/Digits.app";
    // Normal install also replaces its own app bundle completely; ditto merging
    // an older bundle could leave obsolete executable or resource files behind.
    if ([NSFileManager.defaultManager fileExistsAtPath:destination] &&
        ![NSFileManager.defaultManager removeItemAtPath:destination error:&error])
        return DigitsInstallerResult(NO, error.localizedDescription);
    NSDictionary *copied = DigitsInstallerRunTask(@"/usr/bin/ditto", @[source, destination]);
    if ([copied[@"exitStatus"] intValue] != 0)
        return DigitsInstallerResult(NO, [@"The app copy did not complete. " stringByAppendingString:copied[@"output"]]);
    NSDictionary *ownership = DigitsInstallerRunTask(@"/usr/sbin/chown", @[@"-R", @"root:wheel", destination]);
    NSDictionary *permissions = DigitsInstallerRunTask(@"/bin/chmod", @[@"-R", @"go-w", destination]);
    if ([ownership[@"exitStatus"] intValue] != 0 || [permissions[@"exitStatus"] intValue] != 0 ||
        !DigitsInstallerVerifyCode(destination, DIGITS_HOST_IDENTIFIER, &error) ||
        !DigitsInstallerMaintenanceWriteBinding(identifier.UUIDString, &error))
        return DigitsInstallerResult(NO, error.localizedDescription ?: @"The app was copied, but its permissions or display settings did not complete.");
    return DigitsInstallerResult(YES, reinstall ?
        @"Digits was replaced and your display selection was saved. Loaded drivers remain in memory until the single final restart." :
        @"Digits is installed and your display selection is saved. Continue to enable Digits Touch.");
}
