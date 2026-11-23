#import "DigitsInstallerInternal.h"

@implementation DigitsInstallerBackend (InstallApplication)
- (void)installApplicationForDisplayUUID:(NSString *)uuid completion:(DigitsInstallerCompletion)completion {
    NSUUID *identifier = [[NSUUID alloc] initWithUUIDString:uuid];
    if (!identifier || [identifier.UUIDString isEqual:@"00000000-0000-0000-0000-000000000000"]) {
        completion(NO, @"Choose the display that belongs to your touch panel.");
        return;
    }
    BOOL reinstall = self.reinstallRequested;
    [self performOperation:reinstall ? @"Replacing Digits and saving your display…" : @"Installing Digits and saving your display…"
        worker:^NSDictionary *{
            NSError *error = nil;
            NSString *payloads = [NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"Payloads"];
            if (!DigitsInstallerVerifyPayloads(payloads, &error) || !DigitsInstallerStopApplication(&error))
                return DigitsInstallerResult(NO, error.localizedDescription);
            return [self runMaintenanceAction:reinstall ? @"--reinstall-app" : @"--install-app"
                argument:identifier.UUIDString];
        } completion:^(BOOL success, NSString *message) {
            if (success)
                self.touchActivationConfirmed = NO;
            completion(success, message);
        }];
}
@end
