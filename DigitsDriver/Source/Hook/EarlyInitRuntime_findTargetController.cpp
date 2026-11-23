// Find exactly one identity-checked touch controller on the pinned USB route.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
IOService* findTargetController()
{
    auto* matching = IOService::serviceMatching("IOUSBHostDevice");
    if (!matching) return nullptr;
    // getMatchingServices consumes its matching dictionary.
    auto* iterator = IOService::getMatchingServices(matching);
    if (!iterator) return nullptr;
    IOService* found = nullptr;
    unsigned count = 0;
    while (auto* object = iterator->getNextObject()) {
        auto* device = OSDynamicCast(IOService, object);
        if (!device || device->isInactive() ||
            !registryNumberMatches(device, "idVendor", 0x27c0) ||
            !registryNumberMatches(device, "idProduct", 0x0859) ||
            !registryNumberMatches(device, "bcdDevice", 0x0150) ||
            !registryNumberMatches(device, "locationID", kTargetRoute)) continue;
        ++count;
        auto* ancestor = device->copyParentEntry(gIOServicePlane);
        if (!ancestor || !registryClassMatches(ancestor, "AppleUSB20HubPort") ||
            !registryNumberMatches(ancestor, "locationID", kTargetRoute)) {
            if (ancestor) ancestor->release();
            continue;
        }
        for (unsigned depth = 0; ancestor && depth < 24; ++depth) {
            if (registryClassMatches(ancestor, "AppleT8142USBXHCI")) {
                auto* controller = OSDynamicCast(IOService, ancestor);
                if (controller && !controller->isInactive() &&
                    registryNumberMatches(controller, "locationID", 0)) {
                    if (!found) { controller->retain(); found = controller; }
                    else if (found != controller) ++count;
                }
                break;
            }
            auto* parent = ancestor->copyParentEntry(gIOServicePlane);
            ancestor->release();
            ancestor = parent;
        }
        if (ancestor) ancestor->release();
    }
    iterator->release();
    if (count != 1 && found) { found->release(); found = nullptr; }
    return found;
}
}
