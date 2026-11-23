#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (AssociationPause)
- (void)pauseAssociation {
    // A changed/invalid saved identity pauses input. Closing the ordinary GUI does not.
    if (self.associationOnly && self.driverConnection) {
        const kern_return_t result = IOConnectCallScalarMethod(self.driverConnection,
            kDigitsTouchUnbindDisplay, NULL, 0, NULL, NULL);
        if (result != KERN_SUCCESS)
            NSLog(@"Digits Touch: pausing display association returned 0x%08x", result);
    }
    [self disconnectTransport];
}
@end
