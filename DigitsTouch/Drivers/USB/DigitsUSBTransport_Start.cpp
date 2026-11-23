#include "DigitsUSBTransportState.hpp"
#include <os/log.h>

kern_return_t DigitsUSBTransport::Start_Impl(IOService *provider) {
    os_log(OS_LOG_DEFAULT, "Digits Touch: USB startup requested");
    const char *stage = "start superclass";
    kern_return_t result = Start(provider, SUPERDISPATCH);
    if (result != kIOReturnSuccess) {
        os_log(OS_LOG_DEFAULT, "Digits Touch: USB startup failed at %{public}s (0x%08x)", stage, result);
        return result;
    }
    ivars->interface = OSDynamicCast(IOUSBHostInterface, provider);
    if (!ivars->interface) {
        os_log(OS_LOG_DEFAULT, "Digits Touch: provider is not a USB interface (0x%08x)", kIOReturnUnsupported);
        return kIOReturnUnsupported;
    }
    ivars->interface->retain();
    stage = "validate physical USB identity";
    result = ValidateProvider();
    if (result == kIOReturnSuccess) {
        stage = "open USB interface";
        result = ivars->interface->Open(this, 0, nullptr);
        ivars->interfaceOpen = result == kIOReturnSuccess;
    }
    if (result == kIOReturnSuccess) {
        stage = "prepare digitizer endpoint";
        result = PrepareBuffers();
    }
    if (result == kIOReturnSuccess) {
        stage = "validate physical HID descriptor";
        result = ValidateReportDescriptor();
    }
    if (result == kIOReturnSuccess) {
        stage = "publish USB identity";
        result = PublishIdentity("Unbound");
    }
    if (result == kIOReturnSuccess) {
        // Binding is optional. Missing boot configuration must never prevent
        // attachment, endpoint reads, or later app-provided metadata.
        RestorePublishedDisplayBinding();
        stage = "register transport";
        result = RegisterService();
    }
    if (result == kIOReturnSuccess) {
        stage = "queue first digitizer read";
        result = QueueDigitizerRead();
    }
    ivars->lastUSBResult = result;
    // Startup diagnostics distinguish matching/ownership failures from waiting for input.
    // Normal touch frames remain free of logging and registry allocations.
    if (result != kIOReturnSuccess) {
        os_log(OS_LOG_DEFAULT, "Digits Touch: USB startup failed at %{public}s (0x%08x)", stage, result);
        ReleaseResources();
    } else {
        os_log(OS_LOG_DEFAULT, "Digits Touch: USB ready; physical=%llu interface=%llu location=0x%08x",
            ivars->physicalUSBRegistryID, ivars->interfaceRegistryID, ivars->locationID);
    }
    // Initialization belongs to Digits Driver. No mode, reset or configuration request is sent here.
    return result;
}
