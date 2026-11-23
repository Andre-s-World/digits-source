#import "DigitsInstallerActivationSession.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsInstallerActivationSession (Failure)
- (void)request:(OSSystemExtensionRequest *)request didFailWithError:(NSError *)error {
    (void)request;
    // Partial removal may leave no extension. Only this exact public error
    // permits disk cleanup; cancelled or denied requests remain failures.
    if (!self.activation && [error.domain isEqualToString:OSSystemExtensionErrorDomain] &&
        error.code == OSSystemExtensionErrorExtensionNotFound) {
        [self finishWithEvent:@{@"event": @"complete", @"approved": @YES,
            @"restartRequired": @NO, @"message": @"Digits Touch is already absent."} status:0];
        return;
    }
    [self finishWithEvent:@{@"event": @"failed", @"message": error.localizedDescription,
        @"domain": error.domain, @"code": @(error.code)} status:1];
}
@end
#pragma clang diagnostic pop
