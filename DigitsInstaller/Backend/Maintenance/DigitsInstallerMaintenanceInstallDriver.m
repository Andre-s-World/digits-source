#import "DigitsInstallerInternal.h"

NSDictionary *DigitsInstallerMaintenanceInstallDriver(NSString *payloadDirectory) {
    NSError *error = nil;
    if (!DigitsInstallerVerifyPayloads(payloadDirectory, &error))
        return DigitsInstallerResult(NO, error.localizedDescription);
    NSString *bindingPath = @"/Library/Application Support/Digits/DigitsDisplayBinding.plist";
    NSDictionary *binding = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:bindingPath] error:NULL];
    if (![binding[@"Version"] isEqual:@1] || ![binding[@"DisplayUUID"] isKindOfClass:NSString.class])
        return DigitsInstallerResult(NO, @"Save your display selection before installing Digits Driver.");
    NSString *package = [payloadDirectory stringByAppendingPathComponent:DIGITS_DRIVER_PACKAGE];
    NSDictionary *installed = DigitsInstallerRunTask(@"/usr/sbin/installer", @[@"-pkg", package, @"-target", @"/"]);
    if ([installed[@"exitStatus"] intValue] != 0)
        return DigitsInstallerResult(NO, [@"Digits Driver installation did not complete. " stringByAppendingString:installed[@"output"]]);
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:
        @"/Library/Extensions/Digits Driver.kext/Contents/Info.plist"] error:NULL];
    if (![info[@"CFBundleIdentifier"] isEqual:DIGITS_DRIVER_IDENTIFIER] || ![info[@"CFBundleVersion"] isEqual:@"0.2.4"])
        return DigitsInstallerResult(NO, @"The installer finished, but the expected Digits Driver files could not be confirmed.");
    return DigitsInstallerResult(YES, @"Digits Driver files are installed. Complete the macOS approval and password dialog, then check before the final restart. This does not confirm the new driver is running yet.");
}
