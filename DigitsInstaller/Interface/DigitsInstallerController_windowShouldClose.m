#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (WindowCloseGuard)
- (BOOL)windowShouldClose:(NSWindow *)sender {
    (void)sender;
    if (self.busy && !self.previewOnly) {
        self.statusMessage = @"An installation or approval step is in progress. Keep this installer open until it finishes.";
        self.statusLabel.stringValue = self.statusMessage;
        return NO;
    }
    return YES;
}
@end
