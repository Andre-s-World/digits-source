#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (Termination)
- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    self.shuttingDown = YES;
    [self stopBindingWatcher];
    [self stopAssociation];
}
@end
