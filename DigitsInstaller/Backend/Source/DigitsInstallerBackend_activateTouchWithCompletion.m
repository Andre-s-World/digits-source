#import "DigitsInstallerInternal.h"

@implementation DigitsInstallerBackend (ActivateTouch)
- (void)activateTouchWithCompletion:(DigitsInstallerCompletion)completion {
    [self runHostMode:@"--installer-activate-touch" completion:^(BOOL success, NSString *message) {
        self.touchActivationConfirmed = success;
        completion(success, message);
    }];
}
@end
