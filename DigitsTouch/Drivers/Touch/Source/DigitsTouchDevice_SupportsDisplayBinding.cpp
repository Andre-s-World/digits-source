#include "DigitsTouchDevice_internal.hpp"

bool DigitsTouchDevice::SupportsDisplayBinding(const DigitsTouchDisplayBinding *binding) {
    if (!binding) return false;
    // A published HID device keeps its display UUID for this physical connection.
    // Reopening the configuration app must reuse it rather than create another child.
    IOLockLock(ivars->reportLock);
    const bool supported = !ivars->binding.displayUUID[0] ||
        strcmp(ivars->binding.displayUUID, binding->displayUUID) == 0;
    IOLockUnlock(ivars->reportLock);
    return supported;
}
