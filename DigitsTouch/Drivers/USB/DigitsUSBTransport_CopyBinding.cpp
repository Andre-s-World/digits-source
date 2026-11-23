#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::CopyBinding(uint64_t generation,
    DigitsTouchDisplayBinding *binding) {
    if (!binding) return kIOReturnBadArgument;
    IOLockLock(ivars->bindingLock);
    const bool valid = ivars->displayBound && !ivars->stopping &&
        generation == ivars->bindingGeneration;
    if (valid) memcpy(binding, &ivars->binding, sizeof(*binding));
    IOLockUnlock(ivars->bindingLock);
    return valid ? kIOReturnSuccess : kIOReturnNotReady;
}
