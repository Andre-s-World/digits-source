#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (Close)
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return YES;
}
@end
