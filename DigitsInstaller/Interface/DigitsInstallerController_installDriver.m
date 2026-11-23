#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (DriverInstallation)
- (void)installDriver {
    if (self.previewOnly || self.busy)
        return;
    [self setWorking:YES message:@"Installing Digits Driver. Complete the macOS authorization requests."];
    __weak DigitsInstallerController *weakSelf = self;
    [self.backend installDriverWithCompletion:^(BOOL success, NSString *message) {
        DigitsInstallerController *controller = weakSelf;
        if (!controller)
            return;
        controller.driverInstalled = success;
        [controller setWorking:NO message:success ?
            @"Allow Digits Driver, choose Restart Later, and complete the password confirmation. Then check approval here."
            : message];
    }];
}
@end
