#include "DigitsTouchDevice_internal.hpp"

kern_return_t DigitsTouchDevice::setReport(IOMemoryDescriptor *report, IOHIDReportType reportType,
                                           IOOptionBits options, uint32_t completionTimeout,
                                           OSAction *action) {
    (void)completionTimeout;
    // This acknowledges the virtual mode only. It never forwards writes to the physical controller.
    kern_return_t result = kIOReturnUnsupported;
    IOMemoryMap *mapping = nullptr;
    if (report && reportType == kIOHIDReportTypeFeature && (options & 0xff) == 0x21) {
        result = report->CreateMapping(kIOMemoryMapReadOnly, 0, 0, 0, 0, &mapping);
        if (result == kIOReturnSuccess) {
            if (mapping->GetLength() != 3) {
                result = kIOReturnBadArgument;
            } else {
                const uint8_t *bytes = reinterpret_cast<const uint8_t *>(mapping->GetAddress());
                result = bytes[0] == 0x21 && bytes[1] == 2 && bytes[2] == 0 ? kIOReturnSuccess
                                                                            : kIOReturnBadArgument;
            }
            mapping->release();
        }
    }
    if (action) {
        CompleteReport(action, result, result == kIOReturnSuccess ? 3 : 0);
        return kIOReturnSuccess;
    }
    return result;
}
