#include "DigitsTouchDevice_internal.hpp"
bool DigitsTouchDevice::handleStart(IOService *provider) {
    ivars->transport = OSDynamicCast(DigitsUSBTransport, provider);
    if (!ivars->transport) return false;
    ivars->transport->retain();
    // Create reads immutable matching properties; display metadata belongs to the live
    // transport. Copy UUID and generation together before HID asks for its description.
    DigitsTouchDisplayBinding binding = {};
    uint64_t bindingGeneration = 0;
    kern_return_t result = ivars->transport->CopyActiveBinding(
        &binding, &bindingGeneration);
    if (result != kIOReturnSuccess) return false;
    IOLockLock(ivars->reportLock);
    ivars->binding = binding;
    ivars->bindingGeneration = bindingGeneration;
    IOLockUnlock(ivars->reportLock);
    result = IOBufferMemoryDescriptor::Create(kIOMemoryDirectionOutIn,
        DigitsTouch::kReportBytes, 0, &ivars->inputBuffer);
    if (result == kIOReturnSuccess)
        result = ivars->inputBuffer->SetLength(DigitsTouch::kReportBytes);
    if (result == kIOReturnSuccess) result = ivars->inputBuffer->GetAddressRange(&ivars->inputRange);
    if (result != kIOReturnSuccess || ivars->inputRange.length < DigitsTouch::kReportBytes)
        return false;
    // The description callback below already has the current binding before the HID peer starts.
    if (!super::handleStart(provider)) return false;
    IOLockLock(ivars->reportLock);
    ivars->ready = true;
    IOLockUnlock(ivars->reportLock);
    return true;
}
