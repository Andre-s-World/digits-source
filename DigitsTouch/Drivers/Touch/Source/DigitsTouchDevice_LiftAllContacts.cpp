#include "DigitsTouchDevice_internal.hpp"
kern_return_t DigitsTouchDevice::LiftAllContacts() {
    IOLockLock(ivars->reportLock);
    if (!ivars->ready || !ivars->inputBuffer) {
        IOLockUnlock(ivars->reportLock);
        return kIOReturnNotReady;
    }
    uint8_t released[DigitsTouch::kReportBytes];
    memcpy(released, ivars->lastReport, sizeof(released));
    for (size_t index = 0; index < DigitsTouch::kContactSlots; ++index)
        released[1 + index * 5] &= 0xfc;
    // Match the proven companion: make the final release a distinct scan, including wraparound.
    const uint16_t nextScan = static_cast<uint16_t>(released[51] |
        (static_cast<uint16_t>(released[52]) << 8)) + 1;
    released[51] = static_cast<uint8_t>(nextScan);
    released[52] = static_cast<uint8_t>(nextScan >> 8);
    released[53] = 0;
    memcpy(reinterpret_cast<void *>(ivars->inputRange.address), released, sizeof(released));
    // Lifting bypasses the binding check so Unbind/Stop can finish an already accepted drag.
    const kern_return_t result = handleReport(mach_absolute_time(), ivars->inputBuffer,
        sizeof(released), kIOHIDReportTypeInput, 0);
    if (result == kIOReturnSuccess) memcpy(ivars->lastReport, released, sizeof(released));
    IOLockUnlock(ivars->reportLock);
    return result;
}
