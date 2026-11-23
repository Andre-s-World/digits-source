#include "DigitsTouchDevice_internal.hpp"
void DigitsTouchDevice::free() {
    if (ivars) {
        OSSafeReleaseNULL(ivars->inputBuffer);
        OSSafeReleaseNULL(ivars->transport);
        if (ivars->reportLock) IOLockFree(ivars->reportLock);
        IODelete(ivars, DigitsTouchDevice_IVars, 1);
        ivars = nullptr;
    }
    super::free();
}
