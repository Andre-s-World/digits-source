#include "DigitsUSBTransportState.hpp"
bool DigitsUSBTransport::init() {
    if (!super::init()) return false;
    ivars = IONewZero(DigitsUSBTransport_IVars, 1);
    if (!ivars) return false;
    ivars->bindingLock = IOLockAlloc();
    ivars->lastUSBResult = kIOReturnNotReady;
    ivars->lastHIDResult = kIOReturnNotReady;
    return ivars->bindingLock != nullptr;
}
