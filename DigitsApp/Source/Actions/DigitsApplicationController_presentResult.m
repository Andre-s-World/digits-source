#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (ResultAlert)
- (void)presentResult:(BOOL)success title:(NSString *)title message:(NSString *)message {
    NSAlert *alert = [NSAlert new];
    alert.alertStyle = success ? NSAlertStyleInformational : NSAlertStyleWarning;
    alert.messageText = title;
    alert.informativeText = message;
    [alert addButtonWithTitle:@"OK"];
    BOOL needsApproval = !success &&
        [message containsString:@"System Settings"];
    if (needsApproval)
        [alert addButtonWithTitle:@"Open System Settings"];
    [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        if (needsApproval && response == NSAlertSecondButtonReturn)
            [NSWorkspace.sharedWorkspace openURL:
                [NSURL fileURLWithPath:@"/System/Applications/System Settings.app"]];
    }];
}
@end
