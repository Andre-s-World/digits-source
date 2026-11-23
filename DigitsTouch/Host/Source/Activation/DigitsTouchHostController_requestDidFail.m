#import "DigitsTouchHostController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsTouchHostController (RequestFailure)
- (void)request:(OSSystemExtensionRequest *)request didFailWithError:(NSError *)error {
    (void)request;
    self.extensionRequestPending = NO;
    self.activationState =
        [NSString stringWithFormat:@"Request failed: %@ (%@ %ld)", error.localizedDescription,
                                   error.domain, (long)error.code];
    [self updateStatus];
}
@end
#pragma clang diagnostic pop
