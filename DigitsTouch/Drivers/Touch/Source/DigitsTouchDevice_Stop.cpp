#include "DigitsTouchDevice_internal.hpp"
kern_return_t DigitsTouchDevice::Stop_Impl(IOService *provider) {
    LiftAllContacts();
    IOLockLock(ivars->reportLock);
    ivars->ready = false;
    IOLockUnlock(ivars->reportLock);
    return Stop(provider, SUPERDISPATCH);
}
