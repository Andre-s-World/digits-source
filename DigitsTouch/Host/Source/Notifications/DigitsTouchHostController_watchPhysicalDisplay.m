#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (PhysicalDisplayWatch)
- (void)watchPhysicalDisplay:(io_service_t)service {
    if (!self.systemAssociation || !self.notificationPort)
        return;
    uint64_t registryID = 0;
    if (IORegistryEntryGetRegistryEntryID(service, &registryID) != KERN_SUCCESS || registryID == 0)
        return;
    if (!self.displayInterests)
        self.displayInterests = [NSMutableDictionary dictionary];
    if (self.displayInterests[@(registryID)])
        return;
    io_object_t notification = IO_OBJECT_NULL;
    // The service can publish Active/EDID after its arrival. A general-interest
    // subscription observes its public property-change message without polling.
    kern_return_t result = IOServiceAddInterestNotification(self.notificationPort, service,
        kIOGeneralInterest, DigitsTouchDisplayServiceChanged, (__bridge void *)self, &notification);
    if (result != KERN_SUCCESS) {
        NSLog(@"Digits Touch: physical display state subscription failed (0x%08x)", result);
        return;
    }
    self.displayInterests[@(registryID)] = @(notification);
}
@end
