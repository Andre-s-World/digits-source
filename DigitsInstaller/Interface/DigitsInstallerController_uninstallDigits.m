#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (Uninstall)
- (void)uninstallDigits {
    if (self.previewOnly || self.busy)
        return;
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Uninstall Digits?";
    alert.informativeText = @"This removes Digits, Digits Touch and Digits Driver. A restart is required to finish removing the loaded components.";
    [alert addButtonWithTitle:@"Uninstall"];
    [alert addButtonWithTitle:@"Cancel"];
    __weak DigitsInstallerController *weakSelf = self;
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        DigitsInstallerController *controller = weakSelf;
        if (!controller || response != NSAlertFirstButtonReturn)
            return;
        [controller setWorking:YES message:@"Removing Digits…"];
        [controller.backend uninstallWithCompletion:^(BOOL success, NSString *message) {
            [controller setWorking:NO message:message];
            if (success) {
                controller.uninstallCompleted = YES;
                [controller showStep:DigitsInstallerStepFinished];
            }
        }];
    }];
}
@end
