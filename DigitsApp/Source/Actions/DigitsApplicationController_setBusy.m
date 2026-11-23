#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (BusyState)
- (void)setBusy:(BOOL)busy message:(NSString *)message {
    self.operationInProgress = busy;
    self.operationSpinner.hidden = !busy;
    if (busy)
        [self.operationSpinner startAnimation:nil];
    else
        [self.operationSpinner stopAnimation:nil];
    self.approvalHelpLabel.hidden = !busy;
    for (NSButton *button in self.actionButtons)
        button.enabled = !busy;
    self.testerButton.enabled = !busy && self.testerAvailable;
    self.applyButton.enabled = !busy && self.selectedDisplayUUID && ![self.selectedDisplayUUID isEqualToString:self.savedDisplayUUID];
    for (NSView *view in self.displayList.arrangedSubviews) {
        if ([view isKindOfClass:NSControl.class])
            ((NSControl *)view).enabled = !busy;
    }
    self.statusLabel.stringValue = message;
    if (self.displayPanelOpen)
        self.panelStatusLabel.stringValue = message;
    if (!busy && self.statusRefreshDeferred)
        [self scheduleStatusRefresh];
}
@end
