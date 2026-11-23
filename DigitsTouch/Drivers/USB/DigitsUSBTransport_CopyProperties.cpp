#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::CopyProperties_Impl(OSDictionary **properties) {
    if (!properties) return kIOReturnBadArgument;
    const kern_return_t result = CopyProperties(properties, SUPERDISPATCH);
    if (result != kIOReturnSuccess || !*properties) return result;
    DigitsTouchStatus status{};
    CopyStatus(&status);
    OSData *snapshot = OSData::withBytes(&status, sizeof(status));
    if (!snapshot) return kIOReturnNoMemory;
    const bool stored = (*properties)->setObject("DigitsTouchStatus", snapshot);
    snapshot->release();
    return stored ? kIOReturnSuccess : kIOReturnNoMemory;
}
