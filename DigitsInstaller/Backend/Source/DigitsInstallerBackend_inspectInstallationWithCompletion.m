#import "DigitsInstallerInternal.h"

@implementation DigitsInstallerBackend (InspectInstallation)
- (void)inspectInstallationWithCompletion:(void (^)(NSDictionary *installation))completion {
    if (self.operationInProgress) {
        completion(@{@"installed":@NO, @"summary":@"Another Digits operation is still running.",
                     @"driverApprovalAutomaticallyVerifiable":@NO, @"busy":@YES});
        return;
    }
    self.operationInProgress = YES;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSDictionary *state = DigitsInstallerInspectInstallation();
        dispatch_async(dispatch_get_main_queue(), ^{
            self.operationInProgress = NO;
            completion(state);
        });
    });
}
@end
