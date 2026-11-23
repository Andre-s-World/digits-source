#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (BecomeActive)
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    (void)notification;
    if (self.window && self.statusObservationActive && !self.operationInProgress) {
        [self refreshStatus];
        if (self.displayPanelOpen)
            [self refreshDisplayOptions];
    }
}
@end
