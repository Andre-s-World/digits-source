#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (TransportDisconnection)
- (void)disconnectTransport {
    if (self.driverConnection) {
        // The saved association stays with this physical provider after the app closes.
        IOServiceClose(self.driverConnection);
    }
    self.driverConnection = IO_OBJECT_NULL;
    self.connectedTransportRegistryID = 0;
    self.connectedPhysicalUSBRegistryID = 0;
    self.activeBindingIdentity = nil;
}
@end
