#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (TransportConnection)
- (BOOL)connectTransport:(NSDictionary *)transport {
    uint64_t transportRegistryID = [transport[@"TransportRegistryID"] unsignedLongLongValue];
    uint64_t physicalRegistryID = [transport[@"PhysicalUSBRegistryID"] unsignedLongLongValue];
    if (self.driverConnection && self.connectedTransportRegistryID == transportRegistryID &&
        self.connectedPhysicalUSBRegistryID == physicalRegistryID)
        return YES;
    [self disconnectTransport];
    io_service_t service = IOServiceGetMatchingService(
        kIOMainPortDefault, IORegistryEntryIDMatching(transportRegistryID));
    if (!service) {
        self.associationState = @"The touch driver disconnected before association.";
        return NO;
    }
    io_connect_t connection = IO_OBJECT_NULL;
    kern_return_t result =
        IOServiceOpen(service, mach_task_self(), kDigitsTouchUserClientType, &connection);
    IOObjectRelease(service);
    if (result != KERN_SUCCESS) {
        self.associationState = [NSString
            stringWithFormat:@"Cannot open the touch metadata connection (0x%08x).", result];
        return NO;
    }
    self.driverConnection = connection;
    self.connectedTransportRegistryID = transportRegistryID;
    self.connectedPhysicalUSBRegistryID = physicalRegistryID;
    return YES;
}
@end
