#import "DigitsMaintenance.h"

NSError *DigitsMaintenanceError(NSString *message) {
    return [NSError errorWithDomain:@"local.digits.maintenance" code:1
                          userInfo:@{NSLocalizedDescriptionKey:message}];
}
