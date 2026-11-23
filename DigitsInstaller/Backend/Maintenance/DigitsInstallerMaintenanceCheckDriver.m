#import "DigitsInstallerInternal.h"

NSDictionary *DigitsInstallerMaintenanceCheckDriver(void) {
    NSDictionary *diagnostics = DigitsInstallerRunTask(@"/usr/bin/kmutil",
        @[@"print-diagnostics", @"--bundle-path", @"/Library/Extensions/Digits Driver.kext"]);
    NSDictionary *cache = DigitsInstallerRunTask(@"/usr/bin/kmutil",
        @[@"inspect", @"--bundle-identifier", DIGITS_DRIVER_IDENTIFIER, @"--show-extension-info"]);
    // A diagnostics exit code is loadability evidence, not a public approval
    // boolean or proof that the user finished a password dialog. Retain both
    // raw command results without upgrading either into that stronger claim.
    BOOL loadable = [diagnostics[@"exitStatus"] intValue] == 0;
    NSMutableDictionary *result = [DigitsInstallerResult(loadable, loadable ?
        @"The available loadability checks passed. Confirm you completed any macOS approval and password dialog, then restart. Approval completion cannot be automatically verified by a public API." :
        [@"The driver is not yet confirmed loadable. Complete macOS approval in System Settings, then check again. " stringByAppendingString:diagnostics[@"output"]]) mutableCopy];
    result[@"driverApprovalAutomaticallyVerifiable"] = @NO;
    result[@"diagnostics"] = diagnostics;
    result[@"cacheInspection"] = cache;
    result[@"approvalConfirmed"] = @NO;
    return result;
}
