#include "DigitsUSBTransportState.hpp"
void DigitsUSBTransport::free() {
    if (ivars) {
        if (ivars->bindingLock) ReleaseResources();
        if (ivars->bindingLock) IOLockFree(ivars->bindingLock);
        IODelete(ivars, DigitsUSBTransport_IVars, 1);
        ivars = nullptr;
    }
    super::free();
}
