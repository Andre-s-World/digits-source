#include "DigitsUSBTransportState.hpp"

kern_return_t DigitsUSBTransport::CopyPublishedDisplayBinding(
    DigitsTouchDisplayBinding *binding) {
    if (!binding || !ivars->device || !ivars->providerValidated ||
        !ivars->descriptorValidated || ivars->stopping) return kIOReturnNotReady;

    // The KEXT republishes installed boot configuration onto this exact physical
    // USB provider. Registry state is a transport, not the persistent store.
    OSContainer *property = nullptr;
    const kern_return_t result = ivars->device->SearchProperty("DigitsDisplayBinding",
        "IOService", kIOServiceSearchPropertyParents, &property);
    if (result != kIOReturnSuccess) {
        OSSafeReleaseNULL(property);
        return result;
    }
    if (!property) return kIOReturnNotFound;
    OSDictionary *configuration = OSDynamicCast(OSDictionary, property);
    if (!configuration) {
        OSSafeReleaseNULL(property);
        return kIOReturnBadArgument;
    }

    const char *identityNames[] = {"Version", "USBVendorID", "USBProductID", "USBRevision"};
    const uint64_t identityValues[] = {1, DigitsUSB::VendorID, DigitsUSB::ProductID,
                                      DigitsUSB::DeviceRevision};
    bool valid = true;
    for (size_t index = 0; index < 4; ++index) {
        OSNumber *value = OSDynamicCast(OSNumber, configuration->getObject(identityNames[index]));
        valid = valid && value && value->unsigned64BitValue() == identityValues[index];
    }
    OSString *displayUUID = OSDynamicCast(OSString, configuration->getObject("DisplayUUID"));
    valid = valid && displayUUID && displayUUID->getLength() == 36;

    // Optional selectors are compared with current identity; a saved registry ID
    // from another boot is never used to construct the runtime binding.
    const char *selectorNames[] = {"USBLocationID", "PhysicalUSBRegistryID"};
    const uint64_t selectorValues[] = {ivars->locationID, ivars->physicalUSBRegistryID};
    for (size_t index = 0; index < 2; ++index) {
        OSObject *selector = configuration->getObject(selectorNames[index]);
        if (!selector) continue;
        OSNumber *value = OSDynamicCast(OSNumber, selector);
        valid = valid && value && value->unsigned64BitValue() == selectorValues[index];
    }

    // EDID fields document the user's saved selection. Touch does not infer a
    // display from geometry or claim it has independently verified WindowServer.
    const char *displayIdentityNames[] = {"DisplayVendorID", "DisplayProductID", "DisplaySerialNumber"};
    bool hasDisplayIdentity = configuration->getObject("DisplayEDIDSHA256") != nullptr;
    for (size_t index = 0; index < 3; ++index)
        hasDisplayIdentity |= configuration->getObject(displayIdentityNames[index]) != nullptr;
    if (hasDisplayIdentity) {
        for (size_t index = 0; index < 3; ++index) {
            OSNumber *value = OSDynamicCast(OSNumber, configuration->getObject(displayIdentityNames[index]));
            valid = valid && value && value->unsigned64BitValue() <= UINT32_MAX;
        }
        OSString *hash = OSDynamicCast(OSString, configuration->getObject("DisplayEDIDSHA256"));
        valid = valid && hash && hash->getLength() == 64;
        if (hash && hash->getLength() == 64) {
            const char *characters = hash->getCStringNoCopy();
            for (size_t index = 0; index < 64; ++index) {
                const char character = characters[index];
                valid = valid && ((character >= '0' && character <= '9') ||
                    (character >= 'a' && character <= 'f') ||
                    (character >= 'A' && character <= 'F'));
            }
        }
    }

    if (valid) {
        memset(binding, 0, sizeof(*binding));
        binding->version = kDigitsTouchProtocolVersion;
        binding->physicalUSBRegistryID = ivars->physicalUSBRegistryID;
        memcpy(binding->displayUUID, displayUUID->getCStringNoCopy(), 36);
        // BindDisplay validates UUID syntax and rejects the all-zero UUID.
    }
    property->release();
    return valid ? kIOReturnSuccess : kIOReturnBadArgument;
}
