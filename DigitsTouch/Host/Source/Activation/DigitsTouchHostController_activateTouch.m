#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (Activation)
- (void)activateTouch:(id)sender {
    (void)sender;
    if (!self.signedForActivation || self.extensionRequestPending || self.associationOnly)
        return;
    self.activationRequested = YES;
    self.extensionRequestPending = YES;
    OSSystemExtensionRequest *request =
        [OSSystemExtensionRequest activationRequestForExtension:@"local.digits.touch"
                                                          queue:dispatch_get_main_queue()];
    request.delegate = self;
    self.activationState = @"Enable requested. macOS may ask you to approve Digits Touch.";
    [OSSystemExtensionManager.sharedManager submitRequest:request];
    [self updateStatus];
}
@end
