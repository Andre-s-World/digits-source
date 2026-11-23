#include "DigitsUSBTransportState.hpp"
#include "DigitsPhysicalReportDescriptor.hpp"
kern_return_t DigitsUSBTransport::ValidateReportDescriptor() {
    // A one-time standard read validates the report layout; it does not change device state.
    IOBufferMemoryDescriptor *descriptorBuffer = nullptr;
    kern_return_t result = ivars->interface->CreateIOBuffer(
        kIOMemoryDirectionIn, DigitsUSB::PhysicalDescriptorBytes, &descriptorBuffer);
    IOAddressSegment range{};
    if (result == kIOReturnSuccess)
        result = descriptorBuffer->SetLength(DigitsUSB::PhysicalDescriptorBytes);
    if (result == kIOReturnSuccess) result = descriptorBuffer->GetAddressRange(&range);
    if (result == kIOReturnSuccess && range.length < DigitsUSB::PhysicalDescriptorBytes)
        result = kIOReturnNoSpace;
    uint16_t transferred = 0;
    if (result == kIOReturnSuccess)
        result = ivars->interface->DeviceRequest(0x81, 0x06, 0x2200, 0,
            DigitsUSB::PhysicalDescriptorBytes, descriptorBuffer, &transferred, 1000);
    if (result == kIOReturnSuccess &&
        (transferred != sizeof(kDigitsPhysicalReportDescriptor) ||
         memcmp(reinterpret_cast<const void *>(range.address), kDigitsPhysicalReportDescriptor,
                sizeof(kDigitsPhysicalReportDescriptor)) != 0)) result = kIOReturnUnsupported;
    OSSafeReleaseNULL(descriptorBuffer);
    ivars->descriptorValidated = result == kIOReturnSuccess;
    return result;
}
