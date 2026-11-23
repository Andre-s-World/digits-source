#import "DigitsInstallerInternal.h"

@implementation DigitsInstallerBackend (CheckDriver)
- (void)checkDriverApprovalWithCompletion:(DigitsInstallerCompletion)completion {
    [self performOperation:@"Checking the driver’s available startup evidence…" worker:^NSDictionary *{
        return [self runMaintenanceAction:@"--check-driver" argument:nil];
    } completion:completion];
}
@end
