// Create the real derived USB object only for the matching claimed factory context.
#include "EarlyInitRuntime.hpp"

using namespace DigitsEarlyInit;

extern "C" IOUSBHostDevice* XeneonFactoryInner(
    IOService* controller, uint32_t speed, uint16_t address, uint32_t options)
{
    const bool accepting = requestsEnabled();
    const auto original = driverRuntime.originalInnerFactory;
    if (!original) return nullptr;
    bool select = false;
    if (accepting && controller == driverRuntime.controller && speed <= UINT8_MAX &&
        (options & 1u) == 0) {
        const auto thread = reinterpret_cast<uintptr_t>(IOThreadSelf());
        IOSimpleLockLock(driverRuntime.contextLock);
        select = creationContexts.claim(thread, reinterpret_cast<uintptr_t>(controller),
                                  speed, options, kTargetRoute);
        IOSimpleLockUnlock(driverRuntime.contextLock);
    }
    if (!select) return original(controller, speed, address, options);
    // Preserve Apple's allocation/init/ownership sequence. No base instance is
    // relabelled and no already-registered object is swapped after creation.
    auto* result = XeneonStringDevice::withController(
        reinterpret_cast<AppleUSBHostController*>(controller),
        static_cast<UInt8>(speed), address);
    if (result) __atomic_fetch_add(&driverRuntime.selectedDevices, 1u, __ATOMIC_RELAXED);
    else __atomic_fetch_add(&driverRuntime.allocationFailures, 1u, __ATOMIC_RELAXED);
    IOLog("XeneonInit: target factory route=0x%08x address=%u speed=%u created=%u\n",
          kTargetRoute, static_cast<unsigned>(address), speed, result ? 1u : 0u);
    return result;
}
