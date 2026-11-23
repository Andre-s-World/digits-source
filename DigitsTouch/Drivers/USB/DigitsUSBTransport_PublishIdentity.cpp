#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::PublishIdentity(const char *bindingState) {
    OSDictionary *properties = OSDictionary::withCapacity(6);
    if (!properties) return kIOReturnNoMemory;
    const char *names[] = {"PhysicalUSBRegistryID", "USBInterfaceRegistryID", "USBLocationID"};
    const uint64_t values[] = {ivars->physicalUSBRegistryID, ivars->interfaceRegistryID,
                               ivars->locationID};
    bool prepared = true;
    for (size_t index = 0; index < 3; ++index) {
        OSNumber *value = OSNumber::withNumber(values[index], 64);
        prepared = prepared && value && properties->setObject(names[index], value);
        OSSafeReleaseNULL(value);
    }
    OSString *state = OSString::withCString(bindingState);
    OSString *version = OSString::withCString("0.1.6");
    prepared = prepared && state && version && properties->setObject("BindingState", state) &&
        properties->setObject("DriverVersion", version);
    OSSafeReleaseNULL(state);
    OSSafeReleaseNULL(version);
    const kern_return_t result = prepared ? SetProperties(properties) : kIOReturnNoMemory;
    properties->release();
    return result;
}
