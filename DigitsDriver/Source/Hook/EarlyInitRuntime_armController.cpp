// Share the frozen table validation/publication sequence between startup and explicit arm.
#include "EarlyInitRuntime.hpp"
#include "CallableFactory.hpp"

namespace DigitsEarlyInit {
IOReturn armController(IOService* controller)
{
    if (driverRuntime.everPublished) return kIOReturnNotPermitted;
    if (!controller || controller->isInactive() ||
        !registryClassMatches(controller, "AppleT8142USBXHCI") ||
        !registryNumberMatches(controller, "locationID", 0))
        return kIOReturnNotFound;
    driverRuntime.state = "checking";
    controller->retain();
    driverRuntime.controller = controller;
    driverRuntime.workLoop = controller->getWorkLoop();
    if (!driverRuntime.workLoop) {
        driverRuntime.state = "controller-has-no-workloop";
        discardBeforePublication();
        return kIOReturnNotReady;
    }
    driverRuntime.workLoop->retain();
    const uintptr_t outer = reinterpret_cast<uintptr_t>(
        ptrauth_strip(ptrauth_nop_cast(void*, &XeneonFactoryOuter), ptrauth_key_function_pointer));
    const uintptr_t inner = reinterpret_cast<uintptr_t>(
        ptrauth_strip(ptrauth_nop_cast(void*, &XeneonFactoryInner), ptrauth_key_function_pointer));
    const auto prepared = XeneonPinnedController::prepare(
        controller, outer, inner, &driverRuntime.shadow);
    if (prepared != XeneonPinnedController::Status::OK) {
        driverRuntime.state = XeneonPinnedController::statusName(prepared);
        discardBeforePublication();
        return kIOReturnUnsupported;
    }
    driverRuntime.originalOuterFactory = callable<OuterFunction>(driverRuntime.shadow.unsignedOriginalOuter);
    driverRuntime.originalInnerFactory = callable<InnerFunction>(driverRuntime.shadow.unsignedOriginalInner);
    if (OSKextRetainKextWithLoadTag(driverRuntime.loadTag) != KERN_SUCCESS) {
        driverRuntime.state = "module-pin-failed";
        discardBeforePublication();
        return kIOReturnNotPermitted;
    }
    driverRuntime.pinned = true;
    const IOReturn result = driverRuntime.workLoop->runAction(&publishAction, controller);
    if (result != kIOReturnSuccess) {
        driverRuntime.state = "publication-rejected";
        discardBeforePublication();
        return result;
    }
    driverRuntime.state = "armed";
    IOLog("DigitsDriver: armed controller=%llu route=0x%08x; retained for boot\n",
          controller->getRegistryEntryID(), kTargetRoute);
    return kIOReturnSuccess;
}
}
