#include "DigitsTouchDevice_internal.hpp"
kern_return_t DigitsTouchDevice::SubmitPhysicalReport(const uint8_t *report, size_t reportLength) {
    uint8_t normalized[DigitsTouch::kReportBytes];
    if (!DigitsTouch::NormalizePhysicalReport(report, reportLength, normalized))
        return kIOReturnBadArgument;
    IOLockLock(ivars->reportLock);
    if (!ivars->ready || !ivars->inputBuffer) {
        IOLockUnlock(ivars->reportLock);
        return kIOReturnNotReady;
    }
    // Start may initially run on the child's original queue. Its ready publication under this
    // lock makes the transport, binding generation and buffer visible before they are read.
    DigitsTouchDisplayBinding currentBinding{};
    uint64_t currentGeneration = 0;
    if (!ivars->transport || ivars->transport->CopyActiveBinding(
        &currentBinding, &currentGeneration) != kIOReturnSuccess ||
        strcmp(currentBinding.displayUUID, ivars->binding.displayUUID) != 0) {
        IOLockUnlock(ivars->reportLock);
        return kIOReturnNotReady;
    }
    // Reopening the app can resume the same display without replacing the HID device.
    ivars->bindingGeneration = currentGeneration;
    ivars->binding = currentBinding;
    // One persistent buffer is reused only by this child's serialized synchronous submissions.
    memcpy(reinterpret_cast<void *>(ivars->inputRange.address), normalized, sizeof(normalized));
    const kern_return_t result = handleReport(mach_absolute_time(), ivars->inputBuffer,
        sizeof(normalized), kIOHIDReportTypeInput, 0);
    if (result == kIOReturnSuccess) memcpy(ivars->lastReport, normalized, sizeof(normalized));
    IOLockUnlock(ivars->reportLock);
    return result;
}
