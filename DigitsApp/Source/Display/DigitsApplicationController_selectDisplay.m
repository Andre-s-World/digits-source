#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (SelectDisplay)
- (void)selectDisplay:(NSButton *)sender {
    if (self.operationInProgress || sender.tag < 0 || (NSUInteger)sender.tag >= self.displayOptions.count)
        return;
    self.selectedDisplayUUID = self.displayOptions[(NSUInteger)sender.tag].displayUUID;
    for (NSView *view in self.displayList.arrangedSubviews) {
        if ([view isKindOfClass:NSButton.class])
            ((NSButton *)view).state = view == sender ? NSControlStateValueOn : NSControlStateValueOff;
    }
    self.applyButton.enabled = ![self.selectedDisplayUUID isEqualToString:self.savedDisplayUUID];
    self.panelStatusLabel.stringValue = self.applyButton.enabled ? @"Your current binding stays active until restart." : @"This is your current display.";
}
@end
