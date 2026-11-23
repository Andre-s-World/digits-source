#import "DigitsInstallerInternal.h"

@implementation DigitsInstallerBackend (Uninstall)
- (void)uninstallWithCompletion:(DigitsInstallerCompletion)completion {
    [self performOperation:@"Closing the Digits app…" worker:^NSDictionary *{
        NSError *error = nil;
        BOOL stopped = DigitsInstallerStopApplication(&error);
        return DigitsInstallerResult(stopped, stopped ? @"Digits is closed." : error.localizedDescription);
    } completion:^(BOOL stopped, NSString *message) {
        if (!stopped) {
            completion(NO, message);
            return;
        }
        BOOL hostPresent = [NSFileManager.defaultManager fileExistsAtPath:@"/Applications/Digits.app"];
        void (^removeFiles)(void) = ^{
            [self performOperation:@"Digits Touch removal accepted. Removing files and requesting startup-cache authorization…" worker:^NSDictionary *{
                return [self runMaintenanceAction:@"--uninstall" argument:nil];
            } completion:^(BOOL success, NSString *result) {
                if (success && !hostPresent)
                    result = [result stringByAppendingString:@" The installed host was absent, so cached Digits Touch removal could not be separately confirmed."];
                completion(success, result);
            }];
        };
        if (!hostPresent) {
            removeFiles();
            return;
        }
        void (^deactivateHost)(void) = ^{
            [self runHostMode:@"--installer-deactivate-touch" completion:^(BOOL success, NSString *result) {
                if (success)
                    removeFiles();
                else
                    completion(NO, result);
            }];
        };
        NSDictionary *information = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:
            @"/Applications/Digits.app/Contents/Info.plist"] error:NULL];
        NSString *version = [information[@"CFBundleShortVersionString"] isKindOfClass:NSString.class] ?
            information[@"CFBundleShortVersionString"] : nil;
        // Older hosts interpret the installer argument as an ordinary GUI launch
        // and never emit a result. Prepare a verified CLI-capable host first.
        if (!version || [version compare:@"0.2.4" options:NSNumericSearch] == NSOrderedAscending) {
            [self performOperation:@"Preparing macOS removal support for this older Digits app…"
                worker:^NSDictionary *{
                    return [self runMaintenanceAction:@"--prepare-removal-host" argument:nil];
                } completion:^(BOOL success, NSString *result) {
                    if (success)
                        deactivateHost();
                    else
                        completion(NO, result);
                }];
        } else {
            deactivateHost();
        }
    }];
}
@end
