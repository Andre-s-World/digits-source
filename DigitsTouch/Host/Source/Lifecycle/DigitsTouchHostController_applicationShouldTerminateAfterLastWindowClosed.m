#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (WindowLifetime)
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return !self.associationOnly;
}
@end
