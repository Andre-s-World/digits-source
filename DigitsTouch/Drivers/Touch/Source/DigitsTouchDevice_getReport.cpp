#include "DigitsTouchDevice_internal.hpp"

kern_return_t DigitsTouchDevice::getReport(IOMemoryDescriptor *report, IOHIDReportType reportType,
                                           IOOptionBits options, uint32_t completionTimeout,
                                           OSAction *action) {
    (void)completionTimeout;
    const uint8_t maximumContacts[] = {0x0a, 10};
    const uint8_t deviceMode[] = {0x21, 2, 0};
    const uint8_t *featureReport = nullptr;
    uint32_t featureLength = 0;
    if (reportType == kIOHIDReportTypeFeature) {
        if ((options & 0xff) == 0x0a) {
            featureReport = maximumContacts;
            featureLength = sizeof(maximumContacts);
        } else if ((options & 0xff) == 0x21) {
            featureReport = deviceMode;
            featureLength = sizeof(deviceMode);
        }
    }
    kern_return_t result = kIOReturnUnsupported;
    IOMemoryMap *mapping = nullptr;
    if (report && featureReport) {
        result = report->CreateMapping(kIOMemoryMapCacheModeDefault, 0, 0, 0, 0, &mapping);
        if (result == kIOReturnSuccess) {
            if (mapping->GetLength() < featureLength) {
                result = kIOReturnNoSpace;
            } else {
                memcpy(reinterpret_cast<void *>(mapping->GetAddress()), featureReport,
                       featureLength);
            }
            mapping->release();
        }
    }
    if (action) {
        CompleteReport(action, result, result == kIOReturnSuccess ? featureLength : 0);
        return kIOReturnSuccess;
    }
    return result;
}
