#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (Terminate)
- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    [self stopStatusObservation];
}
@end
