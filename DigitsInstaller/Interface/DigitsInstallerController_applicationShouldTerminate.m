#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (QuitGuard)
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    (void)sender;
    if (self.busy && !self.previewOnly) {
        self.statusMessage = @"An installation or approval step is in progress. Keep this installer open until it finishes.";
        self.statusLabel.stringValue = self.statusMessage;
        return NSTerminateCancel;
    }
    return NSTerminateNow;
}
@end
