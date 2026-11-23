// Public IOKit notification replaces login timers and replay/reset recovery.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
IOReturn observeControllerPublication(IOService* control)
{
    auto* matching = IOService::serviceMatching("AppleT8142USBXHCI");
    if (!matching) return kIOReturnNoMemory;
    // addMatchingNotification retains its dictionary and immediately reports an
    // already-published controller. That late case is recorded, never concealed.
    driverRuntime.startupObserver = IOService::addMatchingNotification(
        gIOFirstPublishNotification, matching, &controllerPublished, control, nullptr, 0);
    matching->release();
    return driverRuntime.startupObserver ? kIOReturnSuccess : kIOReturnNoResources;
}
}
