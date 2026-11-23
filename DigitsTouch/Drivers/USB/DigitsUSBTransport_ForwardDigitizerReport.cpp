#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::ForwardDigitizerReport(const uint8_t *report, size_t length) {
    if (!ivars->displayBound || ivars->stopping) return kIOReturnNotReady;
    if (!ivars->touchDevice) {
        if (ivars->touchCreationAttempted) return ivars->touchCreationResult;
        ivars->touchCreationAttempted = true;
        ivars->touchCreationResult = kIOReturnNotReady;
        PublishTouchState("Creating native HID device", kIOReturnNotReady);

        // Create uses the original personality dictionary. The child obtains its current
        // binding directly from this validated transport, not from later SetProperties calls.
        IOService *child = nullptr;
        kern_return_t result = Create(this, "DigitsTouchProperties", &child);
        if (result == kIOReturnSuccess) {
            ivars->touchDevice = OSDynamicCast(DigitsTouchDevice, child);
            if (!ivars->touchDevice) result = kIOReturnUnsupported;
        }
        ivars->touchCreationResult = result;
        if (result != kIOReturnSuccess) {
            // Never repeatedly terminate an incompletely started Apple HID peer. Keep this
            // one failure latched until the physical transport ends and let its owner unwind.
            OSSafeReleaseNULL(child);
            PublishTouchState("Native HID creation failed; input forwarding stopped", result);
            return result;
        }
        // Create manages child startup. Do not replace its dispatch queue after startup begins.
        PublishTouchState("Native HID created; waiting for first accepted input", result);
    }
    // The child's report lock covers asynchronous Start/Stop and the persistent HID buffer.
    return ivars->touchDevice->SubmitPhysicalReport(report, length);
}
