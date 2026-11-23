#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (Restart)
- (void)restartComputer {
    if (self.previewOnly || self.busy || self.step != DigitsInstallerStepFinished)
        return;
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"Restart your Mac now?";
    alert.informativeText = @"Save your open work before continuing. macOS will handle the restart normally.";
    [alert addButtonWithTitle:@"Restart"];
    [alert addButtonWithTitle:@"Cancel"];
    __weak DigitsInstallerController *weakSelf = self;
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        DigitsInstallerController *controller = weakSelf;
        if (!controller || response != NSAlertFirstButtonReturn)
            return;
        NSDictionary *error = nil;
        NSAppleScript *restart = [[NSAppleScript alloc] initWithSource:@"tell application \"System Events\" to restart"];
        [restart executeAndReturnError:&error];
        if (error)
            [controller setWorking:NO message:@"macOS did not restart. You can choose Restart from the Apple menu when you’re ready."];
    }];
}
@end
