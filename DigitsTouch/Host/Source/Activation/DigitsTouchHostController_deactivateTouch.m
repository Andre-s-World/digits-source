#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (Deactivation)
- (void)deactivateTouch:(id)sender {
    (void)sender;
    if (!self.signedForActivation || self.extensionRequestPending || self.associationOnly)
        return;
    NSAlert *confirmation = [[NSAlert alloc] init];
    confirmation.messageText = @"Uninstall Digits Touch?";
    confirmation.informativeText =
        @"macOS will remove the Digits Touch system extension. Digits and Digits Driver remain "
        @"installed. A restart may be required.";
    [confirmation addButtonWithTitle:@"Uninstall"];
    [confirmation addButtonWithTitle:@"Cancel"];
    if ([confirmation runModal] != NSAlertFirstButtonReturn)
        return;
    if (![self disableAutomaticAssociation]) {
        [self updateStatus];
        return;
    }
    [self stopAssociation];
    self.activationRequested = NO;
    self.extensionRequestPending = YES;
    OSSystemExtensionRequest *request =
        [OSSystemExtensionRequest deactivationRequestForExtension:@"local.digits.touch"
                                                            queue:dispatch_get_main_queue()];
    request.delegate = self;
    self.activationState = @"Removal requested. macOS may require confirmation or a restart.";
    self.associationState = @"Display association stopped.";
    [OSSystemExtensionManager.sharedManager submitRequest:request];
    [self updateStatus];
}
@end
