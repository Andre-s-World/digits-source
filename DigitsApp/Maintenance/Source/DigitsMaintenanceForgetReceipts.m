#import "DigitsMaintenance.h"

BOOL DigitsMaintenanceForgetReceipts(NSError **error) {
    for (NSString *identifier in @[@"local.digits.driver.installer", @"local.digits.touch.installer"]) {
        NSError *lookupError = nil;
        if (!DigitsMaintenanceRunCommand(@"/usr/sbin/pkgutil", @[@"--pkg-info", identifier],
                                         NULL, &lookupError))
            continue;
        if (!DigitsMaintenanceRunCommand(@"/usr/sbin/pkgutil", @[@"--forget", identifier],
                                         NULL, error)) {
            *error = DigitsMaintenanceError(@"Digits files were removed, but an installer receipt could not be cleared.");
            return NO;
        }
    }
    return YES;
}
