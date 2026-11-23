#import "DigitsTouchHostController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsTouchHostController (RequestCompletion)
- (void)request:(OSSystemExtensionRequest *)request
    didFinishWithResult:(OSSystemExtensionRequestResult)result {
    (void)request;
    self.extensionRequestPending = NO;
    // Startup association belongs to the drivers. Activation only refreshes this
    // app; it never registers a background helper.
    if (self.activationRequested)
        [self refreshAutomaticBindingState];
    if (result == OSSystemExtensionRequestWillCompleteAfterReboot) {
        self.activationState = @"macOS accepted the request. Restart to complete it.";
    } else {
        self.activationState =
            self.activationRequested ? @"Digits Touch is enabled." : @"Digits Touch was removed.";
        if (self.activationRequested) {
            [self startAssociation];
            [self scheduleAssociationRefresh];
        }
    }
    [self updateStatus];
}
@end
#pragma clang diagnostic pop
