#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (ActivationStatusRefresh)
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    (void)notification;
    if (self.associationOnly)
        return;
    [self refreshAutomaticBindingState];
    [self scheduleAssociationRefresh];
}
@end
