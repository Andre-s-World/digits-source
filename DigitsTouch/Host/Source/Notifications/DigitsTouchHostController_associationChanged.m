#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (AssociationChange)
- (void)associationChanged:(NSNotification *)notification {
    (void)notification;
    // Notifications carry no trusted metadata. Re-read the validated physical registry.
    [self scheduleAssociationRefresh];
}
@end
