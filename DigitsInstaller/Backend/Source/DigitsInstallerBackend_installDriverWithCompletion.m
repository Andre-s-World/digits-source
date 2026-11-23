#import "DigitsInstallerInternal.h"

@implementation DigitsInstallerBackend (InstallDriver)
- (void)installDriverWithCompletion:(DigitsInstallerCompletion)completion {
    if (!self.touchActivationConfirmed) {
        completion(NO, @"Finish enabling Digits Touch before installing Digits Driver.");
        return;
    }
    [self performOperation:@"Installing Digits Driver…" worker:^NSDictionary *{
        return [self runMaintenanceAction:@"--install-driver" argument:nil];
    } completion:completion];
}
@end
