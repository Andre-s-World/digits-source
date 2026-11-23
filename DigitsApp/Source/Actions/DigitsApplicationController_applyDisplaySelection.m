#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (ApplyDisplay)
- (void)applyDisplaySelection:(id)sender {
    (void)sender;
    if (self.operationInProgress || !self.selectedDisplayUUID)
        return;
    NSString *selectedUUID = [self.selectedDisplayUUID copy];
    NSAlert *confirmation = [NSAlert new];
    confirmation.messageText = @"Use this display for touch?";
    confirmation.informativeText = @"Digits will save this selection for the next restart. Binding to a display other than the digitizer’s own display has not been tested. Administrator approval is required.";
    [confirmation addButtonWithTitle:@"Save Binding"];
    [confirmation addButtonWithTitle:@"Cancel"];
    [confirmation beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        if (response != NSAlertFirstButtonReturn)
            return;
        [self setBusy:YES message:@"Saving your display binding…"];
        [self.actions applyDisplayUUID:selectedUUID completion:^(BOOL success, NSString *message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setBusy:NO message:success ? @"Display binding saved. Restart to apply." : @"Binding update did not complete."];
                if (success) {
                    self.savedDisplayUUID = selectedUUID;
                    [self refreshDisplayOptions];
                    [self refreshStatus];
                    self.statusLabel.stringValue = @"Display binding saved. Restart to apply.";
                    self.panelStatusLabel.stringValue = @"Saved for the next restart.";
                    [self presentResult:YES title:@"Restart to apply your display" message:[NSString stringWithFormat:@"%@\n\nChoose Restart from the Apple menu when you’re ready. Your current touch routing remains active until then.", message]];
                } else {
                    [self presentResult:NO title:@"Couldn’t save the binding" message:message];
                }
            });
        }];
    }];
}
@end
