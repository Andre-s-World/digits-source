#import "DigitsTouchHostController.h"
#import <IOKit/IOMessage.h>

void DigitsTouchDisplayServiceChanged(void *context, io_service_t service,
                                     natural_t messageType, void *messageArgument) {
    (void)messageArgument;
    DigitsTouchHostController *controller = (__bridge DigitsTouchHostController *)context;
    if (messageType == kIOMessageServiceIsTerminated) {
        uint64_t registryID = 0;
        if (IORegistryEntryGetRegistryEntryID(service, &registryID) == KERN_SUCCESS) {
            NSNumber *notification = controller.displayInterests[@(registryID)];
            if (notification)
                IOObjectRelease(notification.unsignedIntValue);
            [controller.displayInterests removeObjectForKey:@(registryID)];
        }
    } else if (messageType != kIOMessageServicePropertyChange &&
               messageType != kIOMessageServiceIsResumed &&
               messageType != kIOMessageDeviceHasPoweredOn) {
        return;
    }
    [controller scheduleAssociationRefresh];
}
