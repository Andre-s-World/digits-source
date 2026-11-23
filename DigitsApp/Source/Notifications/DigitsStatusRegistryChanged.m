#import "DigitsApplicationController.h"

void DigitsStatusRegistryChanged(void *context, io_iterator_t iterator) {
    BOOL changed = NO;
    io_service_t service = IO_OBJECT_NULL;
    while ((service = IOIteratorNext(iterator))) {
        changed = YES;
        IOObjectRelease(service);
    }
    // The controller owns this notification port until termination. IOKit
    // delivers its callbacks on the same main queue as observation cleanup.
    if (changed)
        [(__bridge DigitsApplicationController *)context scheduleStatusRefresh];
}
