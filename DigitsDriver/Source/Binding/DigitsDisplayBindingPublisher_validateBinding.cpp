#include "DigitsDisplayBindingPublisher.hpp"

bool DigitsDisplayBindingPublisher::validateBinding(OSDictionary* binding) const
{
    if (!binding || binding->getCount() > 16 ||
        binding->getObject("PhysicalUSBRegistryID")) return false;

    const char* requiredKeys[] = {
        "Version", "USBVendorID", "USBProductID", "USBRevision"
    };
    const uint64_t requiredValues[] = {
        1, targetVendorID, targetProductID, targetRevision
    };
    for (unsigned index = 0; index < 4; ++index) {
        auto* number = OSDynamicCast(OSNumber, binding->getObject(requiredKeys[index]));
        if (!number || number->unsigned64BitValue() != requiredValues[index]) return false;
    }

    auto* location = binding->getObject("USBLocationID");
    auto* locationNumber = OSDynamicCast(OSNumber, location);
    if (location && (!locationNumber ||
        locationNumber->unsigned64BitValue() != targetLocationID)) return false;

    auto* uuid = OSDynamicCast(OSString, binding->getObject("DisplayUUID"));
    if (!uuid || uuid->getLength() != 36) return false;
    const char* uuidText = uuid->getCStringNoCopy();
    bool hasNonzeroDigit = false;
    for (unsigned index = 0; index < 36; ++index) {
        const char character = uuidText[index];
        if (index == 8 || index == 13 || index == 18 || index == 23) {
            if (character != '-') return false;
            continue;
        }
        if (!((character >= '0' && character <= '9') ||
              (character >= 'a' && character <= 'f') ||
              (character >= 'A' && character <= 'F'))) return false;
        hasNonzeroDigit |= character != '0';
    }
    if (!hasNonzeroDigit) return false;

    const char* optionalDisplayKeys[] = {
        "DisplayVendorID", "DisplayProductID", "DisplaySerialNumber"
    };
    auto* edidValue = binding->getObject("DisplayEDIDSHA256");
    bool hasDisplayIdentity = edidValue != nullptr;
    for (unsigned index = 0; index < 3; ++index) {
        hasDisplayIdentity |= binding->getObject(optionalDisplayKeys[index]) != nullptr;
    }
    for (unsigned index = 0; index < 3; ++index) {
        auto* value = binding->getObject(optionalDisplayKeys[index]);
        auto* number = OSDynamicCast(OSNumber, value);
        if (hasDisplayIdentity && (!number ||
            number->unsigned64BitValue() > 0xffffffffULL)) return false;
    }

    auto* edidHash = OSDynamicCast(OSString, edidValue);
    if (hasDisplayIdentity) {
        if (!edidHash || edidHash->getLength() != 64) return false;
        const char* hashText = edidHash->getCStringNoCopy();
        for (unsigned index = 0; index < 64; ++index) {
            const char character = hashText[index];
            if (!((character >= '0' && character <= '9') ||
                  (character >= 'a' && character <= 'f') ||
                  (character >= 'A' && character <= 'F'))) return false;
        }
    }
    return true;
}
