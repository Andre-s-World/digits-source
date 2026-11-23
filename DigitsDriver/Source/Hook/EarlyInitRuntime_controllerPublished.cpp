// Synchronously prepare future creations at controller publication; never reset a device.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
bool controllerPublished(void* target, void*, IOService* service, IONotifier*)
{
    auto* control = static_cast<XeneonEarlyInitControl*>(target);
    if (!control || !service || service->isInactive() ||
        !registryClassMatches(service, "AppleT8142USBXHCI") ||
        !registryNumberMatches(service, "locationID", 0)) return true;
    IOLockLock(driverRuntime.controlLock);
    if (!driverRuntime.everPublished && driverRuntime.automaticArmAttempts == 0) {
        ++driverRuntime.automaticArmAttempts;
        driverRuntime.automaticArmTicks = mach_absolute_time();
        auto* controller = findStartupController();
        driverRuntime.automaticArmResult = controller == service
            ? armController(controller) : kIOReturnNotFound;
        if (!controller || controller != service) driverRuntime.state = "startup-controller-selection-failed";
        if (controller) controller->release();
        IOLog("DigitsDriver: automatic arm result=0x%08x controllers=%llu target-already-present=%llu\n",
              static_cast<unsigned>(driverRuntime.automaticArmResult),
              driverRuntime.startupControllerCount, driverRuntime.startupTargetPresentCount);
    }
    control->publishStatus();
    IOLockUnlock(driverRuntime.controlLock);
    return true;
}
}
