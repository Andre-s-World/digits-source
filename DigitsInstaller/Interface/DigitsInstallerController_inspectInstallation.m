#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (Inspection)
- (void)inspectInstallation {
    [self setWorking:YES message:@"Checking this installation…"];
    __weak DigitsInstallerController *weakSelf = self;
    [self.backend inspectInstallationWithCompletion:^(NSDictionary *result) {
        DigitsInstallerController *controller = weakSelf;
        if (!controller)
            return;
        controller.existingInstallation = [result[@"installed"] boolValue];
        controller.inspectionComplete = YES;
        NSString *summary = [result[@"summary"] isKindOfClass:NSString.class] ? result[@"summary"] : @"Ready when you are.";
        [controller setWorking:NO message:summary];
        if (controller.step == DigitsInstallerStepIntroduction)
            [controller showStep:DigitsInstallerStepIntroduction];
    }];
}
@end
