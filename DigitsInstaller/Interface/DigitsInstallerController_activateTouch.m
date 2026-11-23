#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (TouchActivation)
- (void)activateTouch {
    if (self.previewOnly || self.busy)
        return;
    [self setWorking:YES message:@"Enabling Digits Touch. Complete any macOS approval request; this step will wait."];
    __weak DigitsInstallerController *weakSelf = self;
    [self.backend activateTouchWithCompletion:^(BOOL success, NSString *message) {
        DigitsInstallerController *controller = weakSelf;
        if (!controller)
            return;
        [controller setWorking:NO message:message];
        // Only the backend's accepted OS activation completes this stage, never package exit.
        if (success)
            [controller advanceAfterConfirmedStep:DigitsInstallerStepTouch];
    }];
}
@end
