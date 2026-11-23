// Publish the prepared table only while holding the controller workloop gate.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
IOReturn publishAction(OSObject*, void*, void*, void*, void*)
{
    if (!driverRuntime.controller || !driverRuntime.workLoop || !driverRuntime.workLoop->inGate() ||
        driverRuntime.controller->isInactive() || !driverRuntime.pinned || driverRuntime.everPublished)
        return kIOReturnNotReady;
    uintptr_t expected = driverRuntime.shadow.originalSignedVptr;
    // Initializations are visible before a CPU can enter either callback.
    __atomic_store_n(&driverRuntime.accepting, 1u, __ATOMIC_RELEASE);
    if (!__atomic_compare_exchange_n(
            reinterpret_cast<uintptr_t*>(driverRuntime.controller), &expected,
            driverRuntime.shadow.newSignedVptr, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
        __atomic_store_n(&driverRuntime.accepting, 0u, __ATOMIC_RELEASE);
        return kIOReturnBusy;
    }
    // From this exact publication onward, no failure or disarm may reclaim any
    // published table, function, context, controller, loop, or module reference.
    driverRuntime.everPublished = true;
    driverRuntime.hookInstalled = true;
    __atomic_store_n(&driverRuntime.hookPublicationTicks, mach_absolute_time(), __ATOMIC_RELEASE);
    return kIOReturnSuccess;
}
}
