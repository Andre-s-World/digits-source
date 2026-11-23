#import "DigitsInstallerInternal.h"
#import <unistd.h>

NSDictionary *DigitsInstallerMaintenanceRun(NSArray<NSString *> *arguments) {
    if (geteuid() != 0)
        return DigitsInstallerResult(NO, @"Administrator authorization is required.");
    // The helper accepts fixed verbs and one UUID only. Its own enclosing signed
    // installer determines payload location; callers cannot choose a package/path.
    NSString *bundlePath = arguments.firstObject.stringByStandardizingPath;
    for (NSUInteger index = 0; index < 4; ++index)
        bundlePath = bundlePath.stringByDeletingLastPathComponent;
    NSError *error = nil;
    if (!DigitsInstallerVerifyCode(bundlePath, @"local.digits.installer", &error))
        return DigitsInstallerResult(NO, @"The enclosing Digits Installer signature could not be verified.");
    NSString *payloads = [bundlePath stringByAppendingPathComponent:@"Contents/Resources/Payloads"];
    if (arguments.count == 3 && [arguments[1] isEqual:@"--install-app"])
        return DigitsInstallerMaintenanceInstallApp(arguments[2], NO, payloads);
    if (arguments.count == 3 && [arguments[1] isEqual:@"--reinstall-app"])
        return DigitsInstallerMaintenanceInstallApp(arguments[2], YES, payloads);
    if (arguments.count == 2 && [arguments[1] isEqual:@"--prepare-removal-host"])
        return DigitsInstallerMaintenancePrepareRemovalHost(payloads);
    if (arguments.count == 2 && [arguments[1] isEqual:@"--install-driver"])
        return DigitsInstallerMaintenanceInstallDriver(payloads);
    if (arguments.count == 2 && [arguments[1] isEqual:@"--check-driver"])
        return DigitsInstallerMaintenanceCheckDriver();
    if (arguments.count == 2 && [arguments[1] isEqual:@"--uninstall"])
        return DigitsInstallerMaintenanceUninstall();
    return DigitsInstallerResult(NO, @"Unknown installer action. Nothing changed.");
}
