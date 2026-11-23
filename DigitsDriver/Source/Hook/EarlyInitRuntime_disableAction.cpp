// Disable new selections and restore only the exact table published by this hook.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
IOReturn disableAction(OSObject*, void*, void*, void*, void*)
{
    __atomic_store_n(&driverRuntime.accepting, 0u, __ATOMIC_RELEASE);
    if (!driverRuntime.controller || !driverRuntime.workLoop || !driverRuntime.workLoop->inGate())
        return kIOReturnNotReady;
    uintptr_t expected = driverRuntime.shadow.newSignedVptr;
    if (__atomic_compare_exchange_n(
            reinterpret_cast<uintptr_t*>(driverRuntime.controller), &expected,
            driverRuntime.shadow.originalSignedVptr, false, __ATOMIC_ACQ_REL,
            __ATOMIC_ACQUIRE) || expected == driverRuntime.shadow.originalSignedVptr) {
        driverRuntime.hookInstalled = false;
        return kIOReturnSuccess;
    }
    // Another writer changed the vptr: never overwrite its unexpected value.
    return kIOReturnBusy;
}
}
