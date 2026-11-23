#import "DigitsTouchHostController.h"

void DigitsTouchServicesChanged(void *context, io_iterator_t iterator) {
    DigitsTouchHostController *controller = (__bridge DigitsTouchHostController *)context;
    io_service_t service;
    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
        if (controller.systemAssociation &&
            (IOObjectConformsTo(service, "IOPortTransportStateDisplayPort") ||
             IOObjectConformsTo(service, "AppleDisplay")))
            [controller watchPhysicalDisplay:service];
        IOObjectRelease(service);
    }
    [controller scheduleAssociationRefresh];
}
