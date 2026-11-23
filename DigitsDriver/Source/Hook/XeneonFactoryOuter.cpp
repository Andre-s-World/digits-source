// Record nested factory routes so unrelated creations cannot inherit the target route.
#include "EarlyInitRuntime.hpp"

using namespace DigitsEarlyInit;

extern "C" IOUSBHostDevice* XeneonFactoryOuter(
    IOService* controller, uint32_t speed, uint32_t route, uint32_t options)
{
    const bool accepting = requestsEnabled();
    const auto original = driverRuntime.originalOuterFactory;
    if (!original) return nullptr;
    XeneonCreationContexts::Token token{};
    if (accepting && controller == driverRuntime.controller) {
        const auto thread = reinterpret_cast<uintptr_t>(IOThreadSelf());
        IOSimpleLockLock(driverRuntime.contextLock);
        token = creationContexts.push(thread, reinterpret_cast<uintptr_t>(controller),
                               speed, route, options);
        IOSimpleLockUnlock(driverRuntime.contextLock);
        if (route == kTargetRoute) {
            __atomic_fetch_add(&driverRuntime.targetCreations, 1u, __ATOMIC_RELAXED);
            uint64_t unset = 0;
            __atomic_compare_exchange_n(&driverRuntime.firstTargetFactoryTicks, &unset,
                mach_absolute_time(), false, __ATOMIC_RELAXED, __ATOMIC_RELAXED);
        }
    }
    // Push every route, including foreign nested creations: a child must never
    // inherit the target route from a suspended parent on this same thread.
    auto* result = original(controller, speed, route, options);
    if (token.valid) {
        IOSimpleLockLock(driverRuntime.contextLock);
        creationContexts.pop(token);
        IOSimpleLockUnlock(driverRuntime.contextLock);
    }
    return result;
}
