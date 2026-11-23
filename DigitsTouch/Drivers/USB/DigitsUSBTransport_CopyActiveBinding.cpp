#include "DigitsUSBTransportState.hpp"

kern_return_t DigitsUSBTransport::CopyActiveBinding(DigitsTouchDisplayBinding *binding,
    uint64_t *generation) {
    if (!binding || !generation) return kIOReturnBadArgument;
    IOLockLock(ivars->bindingLock);
    const bool valid = ivars->displayBound && !ivars->stopping;
    if (valid) {
        memcpy(binding, &ivars->binding, sizeof(*binding));
        *generation = ivars->bindingGeneration;
    }
    IOLockUnlock(ivars->bindingLock);
    return valid ? kIOReturnSuccess : kIOReturnNotReady;
}
