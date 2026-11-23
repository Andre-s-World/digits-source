#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (ApplicationInstallation)
- (void)installApplication {
    if (self.previewOnly || self.busy)
        return;
    [self refreshDisplayOptions];
    if (!self.selectedDisplayUUID.length) {
        [self setWorking:NO message:@"The selected display is no longer connected. Choose a connected display."];
        [self showStep:DigitsInstallerStepDisplay];
        return;
    }
    [self showStep:DigitsInstallerStepApplication];
    [self setWorking:YES message:self.backend.reinstallRequested ? @"Replacing the existing Digits installation…" : @"Installing Digits…"];
    __weak DigitsInstallerController *weakSelf = self;
    [self.backend installApplicationForDisplayUUID:self.selectedDisplayUUID completion:^(BOOL success, NSString *message) {
        DigitsInstallerController *controller = weakSelf;
        if (!controller)
            return;
        [controller setWorking:NO message:message];
        if (success)
            [controller advanceAfterConfirmedStep:DigitsInstallerStepApplication];
    }];
}
@end
