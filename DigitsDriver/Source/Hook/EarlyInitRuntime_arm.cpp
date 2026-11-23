// Prepare, validate, and pin the hook before the single gated publication.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
IOReturn arm()
{
    if (driverRuntime.everPublished) return kIOReturnNotPermitted;
    driverRuntime.state = "checking";
    auto* controller = findTargetController();
    if (!controller) { driverRuntime.state = "target-not-found"; return kIOReturnNotFound; }
    const IOReturn result = armController(controller);
    controller->release();
    return result;
}
}
