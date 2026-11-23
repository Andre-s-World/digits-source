#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (PrimaryAction)
- (void)primaryAction:(id)sender {
    (void)sender;
    if (self.busy)
        return;
    if (self.previewOnly) {
        if (self.step == DigitsInstallerStepFinished)
            [self.window close];
        else {
            [self setWorking:NO message:@"Preview — nothing will be installed."];
            [self showStep:(DigitsInstallerStep)(self.step + 1)];
        }
        return;
    }
    if (self.step == DigitsInstallerStepIntroduction) {
        if (!self.previewOnly)
            self.backend.reinstallRequested = self.existingInstallation;
        [self setWorking:NO message:@"Choose the touchscreen’s display to continue."];
        [self showStep:DigitsInstallerStepDisplay];
        return;
    }
    switch (self.step) {
        case DigitsInstallerStepDisplay:
        case DigitsInstallerStepApplication:
            [self installApplication];
            break;
        case DigitsInstallerStepTouch:
            [self activateTouch];
            break;
        case DigitsInstallerStepDriver:
            if (self.driverInstalled)
                [self checkDriverApproval];
            else
                [self installDriver];
            break;
        case DigitsInstallerStepFinished:
            [self restartComputer];
            break;
        default:
            break;
    }
}
@end
