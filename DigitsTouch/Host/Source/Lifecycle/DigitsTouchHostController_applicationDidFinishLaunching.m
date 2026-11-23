#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (Launch)
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    self.activationState = @"Enable Touch activates the driver. Digits Driver restores the saved display association at startup.";
    self.associationState = @"Waiting for a physical display and Digits Touch.";
    self.signedForActivation = [self hasActivationSignature];
    if (!self.associationOnly)
        [self buildWindow];
    [self refreshAutomaticBindingState];
    [self startAssociation];
    [self updateStatus];
}
@end
