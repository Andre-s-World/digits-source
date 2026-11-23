#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::BindDisplay(const DigitsTouchDisplayBinding *binding) {
    // Native HID routing uses the validated UUID. A prelogin metadata helper may
    // not have a WindowServer numeric display ID, which is diagnostic only.
    if (!binding || binding->version != kDigitsTouchProtocolVersion ||
        binding->physicalUSBRegistryID != ivars->physicalUSBRegistryID ||
        binding->reserved[0] || binding->reserved[1] || binding->reserved[2] ||
        binding->displayUUID[36] != 0) return kIOReturnBadArgument;
    bool anyNonzeroDigit = false;
    for (size_t index = 0; index < 36; ++index) {
        const char value = binding->displayUUID[index];
        if (index == 8 || index == 13 || index == 18 || index == 23) {
            if (value != '-') return kIOReturnBadArgument;
        } else {
            if (!((value >= '0' && value <= '9') || (value >= 'a' && value <= 'f') ||
                  (value >= 'A' && value <= 'F'))) return kIOReturnBadArgument;
            anyNonzeroDigit |= value != '0';
        }
    }
    if (!anyNonzeroDigit || ivars->stopping || !ivars->descriptorValidated)
        return kIOReturnNotReady;
    if (ivars->touchDevice && !ivars->touchDevice->SupportsDisplayBinding(binding))
        return kIOReturnUnsupported;
    if (ivars->displayBound && memcmp(&ivars->binding, binding, sizeof(*binding)) == 0)
        return kIOReturnSuccess;
    UnbindDisplay();
    IOLockLock(ivars->bindingLock);
    memcpy(&ivars->binding, binding, sizeof(*binding));
    ++ivars->bindingGeneration;
    ivars->displayBound = true;
    IOLockUnlock(ivars->bindingLock);
    return PublishIdentity("Bound; waiting for physical touch");
}
