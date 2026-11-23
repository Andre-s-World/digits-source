#include "DigitsUSBTransportState.hpp"
#include <os/log.h>

kern_return_t DigitsUSBTransport::PublishTouchState(const char *state, kern_return_t result) {
    // Lifecycle transitions only: no registry allocation or logging on ordinary touch frames.
    os_log(OS_LOG_DEFAULT, "Digits Touch: %{public}s (0x%08x)", state, result);
    OSDictionary *properties = OSDictionary::withCapacity(3);
    OSString *description = OSString::withCString(state);
    OSNumber *status = OSNumber::withNumber(static_cast<uint32_t>(result), 32);
    OSNumber *attempts = OSNumber::withNumber(ivars->touchCreationAttempted ? 1 : 0, 32);
    const bool prepared = properties && description && status && attempts &&
        properties->setObject("HIDPublicationState", description) &&
        properties->setObject("HIDPublicationResult", status) &&
        properties->setObject("HIDCreationAttempts", attempts);
    const kern_return_t published = prepared ? SetProperties(properties) : kIOReturnNoMemory;
    OSSafeReleaseNULL(attempts);
    OSSafeReleaseNULL(status);
    OSSafeReleaseNULL(description);
    OSSafeReleaseNULL(properties);
    return published;
}
