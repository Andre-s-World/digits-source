#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (Uninstall)
- (void)uninstallDigits:(id)sender {
    (void)sender;
    if (self.operationInProgress)
        return;
    NSAlert *confirmation = [NSAlert new];
    confirmation.alertStyle = NSAlertStyleWarning;
    confirmation.messageText = @"Uninstall Digits?";
    confirmation.informativeText = @"This removes Digits Touch, Digits Driver and the Digits app together. The first password prompt authorizes the removal tool. Updating the startup cache can require a separate macOS approval; keep Digits open and complete the separate macOS password prompt for your signed-in account. A restart completes removal; the running kernel driver will not be force-unloaded.";
    [confirmation addButtonWithTitle:@"Uninstall Digits"];
    [confirmation addButtonWithTitle:@"Cancel"];
    [confirmation beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        if (response != NSAlertFirstButtonReturn)
            return;
        [self setBusy:YES message:@"Uninstalling Digits…"];
        [self.actions uninstallDigitsWithCompletion:^(BOOL success, NSString *message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success)
                    [self stopStatusObservation];
                [self setBusy:NO message:success ? @"Digits was removed. Restart to finish." : @"Uninstall did not complete."];
                if (success) {
                    for (NSButton *button in self.actionButtons)
                        button.enabled = NO;
                    self.applyButton.enabled = NO;
                    [self presentResult:YES title:@"Restart to finish uninstalling" message:[NSString stringWithFormat:@"%@\n\nChoose Restart from the Apple menu to finish removing the loaded drivers.", message]];
                } else {
                    [self presentResult:NO title:@"Uninstall did not complete" message:message];
                }
            });
        }];
    }];
}
@end
