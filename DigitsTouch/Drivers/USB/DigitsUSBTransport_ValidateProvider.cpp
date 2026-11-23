#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::ValidateProvider() {
    kern_return_t result = ivars->interface->CopyDevice(&ivars->device);
    if (result != kIOReturnSuccess || !ivars->device) return kIOReturnNoDevice;
    const IOUSBDeviceDescriptor *deviceDescriptor = ivars->device->CopyDeviceDescriptor();
    if (!deviceDescriptor) return kIOReturnNoDevice;
    const bool deviceMatches = deviceDescriptor->bLength == sizeof(IOUSBDeviceDescriptor) &&
        deviceDescriptor->bDescriptorType == 1 &&
        USBToHost16(deviceDescriptor->idVendor) == DigitsUSB::VendorID &&
        USBToHost16(deviceDescriptor->idProduct) == DigitsUSB::ProductID &&
        USBToHost16(deviceDescriptor->bcdDevice) == DigitsUSB::DeviceRevision;
    IOUSBHostFreeDescriptor(deviceDescriptor);
    if (!deviceMatches) return kIOReturnUnsupported;

    const IOUSBConfigurationDescriptor *configuration =
        ivars->interface->CopyConfigurationDescriptor();
    if (!configuration) return kIOReturnNoDevice;
    const IOUSBInterfaceDescriptor *interfaceDescriptor =
        ivars->interface->GetInterfaceDescriptor(configuration);
    const bool interfaceMatches = configuration->bConfigurationValue == 1 &&
        interfaceDescriptor && interfaceDescriptor->bLength == sizeof(IOUSBInterfaceDescriptor) &&
        interfaceDescriptor->bInterfaceNumber == 0 && interfaceDescriptor->bAlternateSetting == 0 &&
        interfaceDescriptor->bInterfaceClass == 3 && interfaceDescriptor->bInterfaceSubClass == 0 &&
        interfaceDescriptor->bInterfaceProtocol == 0 && interfaceDescriptor->bNumEndpoints == 1;
    IOUSBHostFreeDescriptor(configuration);
    if (!interfaceMatches) return kIOReturnUnsupported;
    result = ivars->device->GetRegistryEntryID(&ivars->physicalUSBRegistryID);
    if (result == kIOReturnSuccess)
        result = ivars->interface->GetRegistryEntryID(&ivars->interfaceRegistryID);
    if (result != kIOReturnSuccess || !ivars->physicalUSBRegistryID || !ivars->interfaceRegistryID)
        return kIOReturnNoDevice;
    OSDictionary *properties = nullptr;
    if (ivars->device->CopyProperties(&properties) == kIOReturnSuccess && properties) {
        OSNumber *location = OSDynamicCast(OSNumber, properties->getObject("locationID"));
        if (location) ivars->locationID = location->unsigned32BitValue();
        properties->release();
    }
    ivars->providerValidated = true;
    return kIOReturnSuccess;
}
