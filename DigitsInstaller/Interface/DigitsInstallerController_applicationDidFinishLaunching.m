#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (Launch)
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    [self buildWindow];
    [NSApp activateIgnoringOtherApps:YES];
    [self inspectInstallation];
}
@end
