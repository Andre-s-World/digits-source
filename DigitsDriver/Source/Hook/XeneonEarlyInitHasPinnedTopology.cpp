// Recheck the physical route after attach, before changing any enumeration string.
#include "EarlyInitRuntime.hpp"

extern "C" bool XeneonEarlyInitHasPinnedTopology(IORegistryEntry* device)
{
    using namespace DigitsEarlyInit;
    if (!device || !requestsEnabled() || !driverRuntime.controller) return false;
    auto* ancestor = device->copyParentEntry(gIOServicePlane);
    if (!ancestor || !registryClassMatches(ancestor, "AppleUSB20HubPort") ||
        !registryNumberMatches(ancestor, "locationID", kTargetRoute)) {
        if (ancestor) ancestor->release();
        return false;
    }
    bool matches = false;
    for (unsigned depth = 0; ancestor && depth < 24; ++depth) {
        if (registryClassMatches(ancestor, "AppleT8142USBXHCI")) {
            matches = ancestor == driverRuntime.controller &&
                registryNumberMatches(ancestor, "locationID", 0) &&
                !driverRuntime.controller->isInactive();
            break;
        }
        auto* parent = ancestor->copyParentEntry(gIOServicePlane);
        ancestor->release();
        ancestor = parent;
    }
    if (ancestor) ancestor->release();
    return matches;
}
