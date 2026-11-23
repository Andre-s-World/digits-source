// Select the pinned controller without requiring the touchscreen to enumerate first.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
IOService* findStartupController()
{
    driverRuntime.startupControllerCount = 0;
    driverRuntime.startupTargetPresentCount = 0;
    IOService* selected = nullptr;
    auto* controllerMatching = IOService::serviceMatching("AppleT8142USBXHCI");
    auto* controllers = controllerMatching ? IOService::getMatchingServices(controllerMatching) : nullptr;
    if (!controllers) return nullptr;
    while (auto* object = controllers->getNextObject()) {
        auto* controller = OSDynamicCast(IOService, object);
        if (!controller || controller->isInactive() ||
            !registryClassMatches(controller, "AppleT8142USBXHCI") ||
            !registryNumberMatches(controller, "locationID", 0)) continue;
        ++driverRuntime.startupControllerCount;
        if (!selected) { controller->retain(); selected = controller; }
    }
    controllers->release();
    // This snapshot detects known-late startup; zero is not proof that enumeration
    // has not begun, because a device can be under construction before registration.
    auto* deviceMatching = IOService::serviceMatching("IOUSBHostDevice");
    auto* devices = deviceMatching ? IOService::getMatchingServices(deviceMatching) : nullptr;
    if (!devices) {
        if (selected) selected->release();
        return nullptr;
    }
    while (auto* object = devices->getNextObject()) {
        auto* device = OSDynamicCast(IOService, object);
        if (device && !device->isInactive() &&
            registryNumberMatches(device, "idVendor", 0x27c0) &&
            registryNumberMatches(device, "idProduct", 0x0859) &&
            registryNumberMatches(device, "bcdDevice", 0x0150) &&
            registryNumberMatches(device, "locationID", kTargetRoute))
            ++driverRuntime.startupTargetPresentCount;
    }
    devices->release();
    if (driverRuntime.startupControllerCount != 1 || driverRuntime.startupTargetPresentCount > 1) {
        if (selected) selected->release();
        return nullptr;
    }
    return selected;
}
}
