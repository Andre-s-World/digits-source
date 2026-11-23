#import "DigitsMaintenance.h"
#import <unistd.h>

BOOL DigitsMaintenanceRun(NSArray<NSString *> *arguments, NSError **error) {
    if (arguments.count == 4 && [arguments[1] isEqualToString:@"--prepare-binding"])
        return DigitsMaintenancePrepareBinding(arguments[2], arguments[3], error);
    // Only these fixed actions can cross the one-time administrator boundary.
    // There is no arbitrary command, file path, driver unload, or USB operation.
    if (geteuid() != 0) {
        *error = DigitsMaintenanceError(@"Administrator authorization is required.");
        return NO;
    }
    if (arguments.count == 3 && [arguments[1] isEqualToString:@"--apply-binding"])
        return DigitsMaintenanceApplyBinding(arguments[2], error);
    if (arguments.count == 2 && [arguments[1] isEqualToString:@"--uninstall"])
        return DigitsMaintenanceUninstall(error);
    *error = DigitsMaintenanceError(@"Unknown Digits maintenance operation. Nothing changed.");
    return NO;
}
