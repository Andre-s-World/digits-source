#import "DigitsInstallerInternal.h"

NSDictionary *DigitsInstallerResult(BOOL success, NSString *message) {
    return @{ @"success":@(success), @"message":message ?: @"The operation did not complete." };
}
