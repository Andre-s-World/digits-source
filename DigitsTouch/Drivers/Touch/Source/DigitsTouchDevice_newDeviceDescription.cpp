#include "DigitsTouchDevice_internal.hpp"
OSDictionary *DigitsTouchDevice::newDeviceDescription() {
    DigitsTouchDisplayBinding current{};
    if (!ivars->transport || ivars->transport->CopyBinding(
        ivars->bindingGeneration, &current) != kIOReturnSuccess) return nullptr;
    OSDictionary *description = OSDictionary::withCapacity(13);
    if (!description) return nullptr;
    struct StringProperty { const char *name; const char *value; };
    const StringProperty strings[] = {
        {kIOHIDTransportKey, "Virtual"}, {kIOHIDManufacturerKey, "Digits"},
        {kIOHIDProductKey, "Digits Touch"}, {kIOHIDSerialNumberKey, "Digits-Touch"},
        {"displayUUID", ivars->binding.displayUUID},
    };
    for (const auto &property : strings) {
        OSString *value = OSString::withCString(property.value);
        if (!value || !description->setObject(property.name, value)) {
            OSSafeReleaseNULL(value); description->release(); return nullptr;
        }
        value->release();
    }
    struct NumberProperty { const char *name; uint32_t value; };
    const NumberProperty numbers[] = {
        {kIOHIDVendorIDKey, 0x27c0}, {kIOHIDProductIDKey, 0x085a},
        {kIOHIDVersionNumberKey, 1}, {kIOHIDCountryCodeKey, 0},
    };
    for (const auto &property : numbers) {
        OSNumber *value = OSNumber::withNumber(property.value, 32);
        if (!value || !description->setObject(property.name, value)) {
            OSSafeReleaseNULL(value); description->release(); return nullptr;
        }
        value->release();
    }
    // These mirror the working touchscreen profile, scoped to this new child only.
    // IOUserHIDDevice registers only after its own initialization has completed.
    if (!description->setObject("RegisterService", kOSBooleanTrue) ||
        !description->setObject("Built-In", kOSBooleanFalse) ||
        !description->setObject("DisplayIntegrated", kOSBooleanTrue) ||
        !description->setObject("DigitizerCollectionDispatch", kOSBooleanTrue)) {
        description->release(); return nullptr;
    }
    return description;
}
