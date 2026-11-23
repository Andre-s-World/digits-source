#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (DisplaySelection)
- (void)selectDisplay:(NSButton *)sender {
    if (self.busy || sender.tag < 0 || (NSUInteger)sender.tag >= self.displayOptions.count)
        return;
    self.selectedDisplayUUID = self.displayOptions[(NSUInteger)sender.tag].displayUUID;
    [self setWorking:NO message:@"Display selected. Install will save this association for Digits Touch."];
    // Rebuild only the selection screen so radio states remain consistent across separate rows.
    [self showStep:DigitsInstallerStepDisplay];
}
@end
