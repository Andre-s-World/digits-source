#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (PasswordConfirmation)
- (void)confirmPassword:(NSButton *)sender {
    if (self.previewOnly || self.busy)
        return;
    self.passwordConfirmationReceived = sender.state == NSControlStateValueOn;
    if (self.passwordConfirmationReceived && self.driverLoadabilityConfirmed)
        [self advanceAfterConfirmedStep:DigitsInstallerStepDriver];
}
@end
