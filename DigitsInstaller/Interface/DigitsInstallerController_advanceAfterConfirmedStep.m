#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (ConfirmedTransition)
- (void)advanceAfterConfirmedStep:(DigitsInstallerStep)step {
    if (self.previewOnly || self.step != step)
        return;
    NSString *message = step == DigitsInstallerStepApplication ? @"Digits is installed. Next: Digits Touch."
        : step == DigitsInstallerStepTouch ? @"Digits Touch is enabled. Next: Digits Driver."
        : @"Approval and password confirmation are complete. Finishing up…";
    [self setWorking:YES message:message];
    NSUInteger generation = self.transitionGeneration;
    __weak DigitsInstallerController *weakSelf = self;
    // This small pause presents a confirmed result. Permission waits themselves have no timer.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        DigitsInstallerController *controller = weakSelf;
        if (!controller || controller.step != step || controller.transitionGeneration != generation)
            return;
        [controller setWorking:NO message:@""];
        [controller showStep:(DigitsInstallerStep)(step + 1)];
        if (controller.step == DigitsInstallerStepTouch)
            [controller activateTouch];
        else if (controller.step == DigitsInstallerStepDriver)
            [controller installDriver];
    });
}
@end
