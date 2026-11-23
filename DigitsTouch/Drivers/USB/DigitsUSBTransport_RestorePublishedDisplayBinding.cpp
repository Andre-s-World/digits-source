#include "DigitsUSBTransportState.hpp"
#include <os/log.h>

kern_return_t DigitsUSBTransport::RestorePublishedDisplayBinding() {
    if (ivars->displayBound) return kIOReturnSuccess;
    if (ivars->publishedBindingRejected || ivars->stopping) return kIOReturnNotReady;

    ++ivars->publishedBindingAttempts;
    DigitsTouchDisplayBinding binding = {};
    kern_return_t result = CopyPublishedDisplayBinding(&binding);
    if (result == kIOReturnSuccess) result = BindDisplay(&binding);
    if (result == kIOReturnSuccess) {
        OSDictionary *properties = OSDictionary::withCapacity(1);
        OSString *source = OSString::withCString("Digits Driver configuration");
        if (properties && source && properties->setObject("DisplayBindingSource", source))
            SetProperties(properties);
        OSSafeReleaseNULL(source);
        OSSafeReleaseNULL(properties);
        os_log(OS_LOG_DEFAULT, "Digits Touch: restored published display binding; physical=%llu UUID=%{public}s",
            ivars->physicalUSBRegistryID, binding.displayUUID);
    } else if (result == kIOReturnBadArgument) {
        // Invalid installed metadata cannot improve during this connection. Avoid
        // repeated parsing/logging; a fresh connection loads the next configuration.
        ivars->publishedBindingRejected = true;
        os_log(OS_LOG_DEFAULT, "Digits Touch: published display binding rejected (0x%08x); touch remains unbound", result);
    } else if (ivars->publishedBindingAttempts == 1) {
        os_log(OS_LOG_DEFAULT, "Digits Touch: no published display binding yet (0x%08x); USB input remains available", result);
    }
    return result;
}
