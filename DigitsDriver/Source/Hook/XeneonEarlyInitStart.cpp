// Register event-driven startup and one administrator control service for this boot.
#include "EarlyInitRuntime.hpp"

using namespace DigitsEarlyInit;

extern "C" kern_return_t XeneonEarlyInitStart(kmod_info_t* info, void*)
{
    // Log before any fallible work so a boot record can distinguish demand-load
    // rejection from a module that entered but failed to initialize.
    IOLog("DigitsDriver 0.2.4: module start entered; trigger=IOResources/IOKit\n");
    if (!info || driverRuntime.controlLock) {
        IOLog("DigitsDriver 0.2.4: startup rejected; module-info=%s existing-control=%s\n",
              info ? "present" : "missing", driverRuntime.controlLock ? "yes" : "no");
        return KERN_FAILURE;
    }
    driverRuntime.loadTag = static_cast<OSKextLoadTag>(info->id);
    driverRuntime.moduleStartTicks = mach_absolute_time();
    driverRuntime.automaticArmResult = kIOReturnNotReady;
    driverRuntime.controlLock = IOLockAlloc();
    driverRuntime.contextLock = IOSimpleLockAlloc();
    if (!driverRuntime.controlLock || !driverRuntime.contextLock) {
        IOLog("DigitsDriver 0.2.4: startup failed; lock allocation\n");
        if (driverRuntime.contextLock) IOSimpleLockFree(driverRuntime.contextLock);
        if (driverRuntime.controlLock) IOLockFree(driverRuntime.controlLock);
        driverRuntime.contextLock = nullptr; driverRuntime.controlLock = nullptr;
        return KERN_RESOURCE_SHORTAGE;
    }
    auto* control = new XeneonEarlyInitControl;
    auto* provider = IOService::getResourceService();
    if (!control || !provider || !control->init() || !control->attach(provider)) {
        IOLog("DigitsDriver 0.2.4: startup failed; control initialization or resource attachment\n");
        if (control) control->release();
        IOSimpleLockFree(driverRuntime.contextLock); IOLockFree(driverRuntime.controlLock);
        driverRuntime.contextLock = nullptr; driverRuntime.controlLock = nullptr;
        return KERN_FAILURE;
    }
    driverRuntime.state = "waiting-for-controller-publication";
    control->setName("XeneonEarlyInitControl");
    // Registration can synchronously invoke the callback for an existing controller.
    // From here onward the observer/control are boot-long; do not fail module start.
    const IOReturn observerResult = observeControllerPublication(control);
    if (observerResult != kIOReturnSuccess) {
        driverRuntime.automaticArmResult = observerResult;
        driverRuntime.state = "startup-observer-registration-failed";
    }
    control->publishStatus();
    // Keep the initial service reference for this boot. No fallible work or
    // startup failure occurs after a callable control service is published.
    control->registerService();
    IOLog("DigitsDriver: startup observer result=0x%08x; no reset or reconfiguration\n",
          static_cast<unsigned>(observerResult));
    return KERN_SUCCESS;
}
