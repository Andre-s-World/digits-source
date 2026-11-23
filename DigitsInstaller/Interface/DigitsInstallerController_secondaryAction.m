#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (SecondaryAction)
- (void)secondaryAction:(id)sender {
    (void)sender;
    if (self.busy)
        return;
    if (self.step == DigitsInstallerStepDisplay) {
        [self setWorking:NO message:@"Connected displays refreshed."];
        [self showStep:DigitsInstallerStepDisplay];
    } else if (self.step == DigitsInstallerStepIntroduction && !self.previewOnly) {
        [self uninstallDigits];
    } else if (self.step == DigitsInstallerStepFinished) {
        [self.window close];
    }
}
@end
