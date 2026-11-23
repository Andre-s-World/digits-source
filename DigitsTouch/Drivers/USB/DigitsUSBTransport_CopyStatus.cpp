#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::CopyStatus(DigitsTouchStatus *status) {
    if (!status) return kIOReturnBadArgument;
    memset(status, 0, sizeof(*status));
    status->version = kDigitsTouchProtocolVersion;
    status->flags = (ivars->providerValidated ? kDigitsTouchProviderValidated : 0) |
        (ivars->descriptorValidated ? kDigitsTouchDescriptorValidated : 0) |
        (ivars->displayBound ? kDigitsTouchDisplayBound : 0) |
        (ivars->touchDevice ? kDigitsTouchChildCreated : 0) |
        (ivars->stopping ? kDigitsTouchStopping : 0);
    status->physicalUSBRegistryID = ivars->physicalUSBRegistryID;
    status->interfaceRegistryID = ivars->interfaceRegistryID;
    status->usbLocationID = ivars->locationID;
    status->displayID = ivars->binding.displayID;
    status->completedTransfers = ivars->completedTransfers;
    status->validPhysicalReports = ivars->validPhysicalReports;
    status->forwardedReports = ivars->forwardedReports;
    status->rejectedReports = ivars->rejectedReports;
    status->lastUSBResult = ivars->lastUSBResult;
    status->lastHIDResult = ivars->lastHIDResult;
    memcpy(status->displayUUID, ivars->binding.displayUUID, sizeof(status->displayUUID));
    return kIOReturnSuccess;
}
