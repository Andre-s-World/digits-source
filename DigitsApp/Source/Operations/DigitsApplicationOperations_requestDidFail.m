#import "DigitsApplicationOperations.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsApplicationOperations (RequestFailed)
- (void)request:(OSSystemExtensionRequest *)request didFailWithError:(NSError *)error {
    (void)request;
    DigitsActionCompletion completion = self.uninstallCompletion;
    self.uninstallCompletion = nil;
    if (!completion)
        return;
    // A partially removed installation still needs its app and KEXT cleaned up.
    // Only Apple's precise "already absent" result permits that continuation;
    // cancellation, permission and unrelated errors retain the installed files.
    if ([error.domain isEqualToString:OSSystemExtensionErrorDomain] &&
        error.code == OSSystemExtensionErrorExtensionNotFound) {
        [self runMaintenanceAction:@"--uninstall" argument:@"" completion:completion];
        return;
    }
    completion(NO, [NSString stringWithFormat:@"macOS did not remove Digits Touch: %@. Installed files were kept.",
        error.localizedDescription]);
}
@end
#pragma clang diagnostic pop
