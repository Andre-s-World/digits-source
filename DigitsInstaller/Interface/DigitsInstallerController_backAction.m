#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (BackAction)
- (void)backAction:(id)sender {
    (void)sender;
    if (self.previewOnly && !self.busy && self.step > DigitsInstallerStepIntroduction) {
        [self setWorking:NO message:@"Preview — nothing will be installed."];
        [self showStep:(DigitsInstallerStep)(self.step - 1)];
        return;
    }
    if (!self.busy && self.step == DigitsInstallerStepDisplay) {
        [self setWorking:NO message:@"Ready when you are."];
        [self showStep:DigitsInstallerStepIntroduction];
    }
}
@end
