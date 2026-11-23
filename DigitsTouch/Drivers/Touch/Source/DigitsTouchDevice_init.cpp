#include "DigitsTouchDevice_internal.hpp"
bool DigitsTouchDevice::init() {
    if (!super::init()) return false;
    ivars = IONewZero(DigitsTouchDevice_IVars, 1);
    if (!ivars) return false;
    ivars->reportLock = IOLockAlloc();
    ivars->lastReport[0] = 0x0d;
    return ivars->reportLock != nullptr;
}
