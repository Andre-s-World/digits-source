#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (DriverApproval)
- (void)checkDriverApproval {
    if (self.previewOnly || self.busy || !self.driverInstalled)
        return;
    [self setWorking:YES message:@"Checking whether macOS permits Digits Driver to load…"];
    __weak DigitsInstallerController *weakSelf = self;
    [self.backend checkDriverApprovalWithCompletion:^(BOOL success, NSString *message) {
        DigitsInstallerController *controller = weakSelf;
        if (!controller)
            return;
        controller.driverLoadabilityConfirmed = success;
        [controller setWorking:NO message:success && !controller.passwordConfirmationReceived ?
            @"Loadability confirmed. Please confirm that you completed the password step after choosing Restart Later."
            : message];
        if (success && controller.passwordConfirmationReceived)
            [controller advanceAfterConfirmedStep:DigitsInstallerStepDriver];
    }];
}
@end
