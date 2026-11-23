#include "DigitsDisplayBindingPublisher.hpp"
#include <IOKit/IOLib.h>

bool DigitsDisplayBindingPublisher::publishToPhysicalDevice(IOService* device)
{
    if (!binding_ || !device || device->isInactive() ||
        !device->metaCast("IOUSBHostDevice")) return false;

    const char* identityKeys[] = { "idVendor", "idProduct", "bcdDevice", "locationID" };
    const uint64_t identityValues[] = {
        targetVendorID, targetProductID, targetRevision, targetLocationID
    };
    for (unsigned index = 0; index < 4; ++index) {
        auto* value = device->copyProperty(identityKeys[index]);
        auto* number = OSDynamicCast(OSNumber, value);
        const bool matches = number && number->unsigned64BitValue() == identityValues[index];
        if (value) value->release();
        if (!matches) return false;
    }

    auto* publishedBinding = OSDictionary::withDictionary(binding_);
    if (!publishedBinding) return false;
    publishedBinding->setOptions(0, OSCollection::kImmutable);
    // Persisted configuration never contains a registry ID. Add the current
    // physical instance now so Digits Touch can reject stale or foreign sources.
    auto* registryID = OSNumber::withNumber(device->getRegistryEntryID(), 64);
    auto* locationID = OSNumber::withNumber(targetLocationID, 32);
    const bool prepared = registryID && locationID &&
        publishedBinding->setObject("PhysicalUSBRegistryID", registryID) &&
        publishedBinding->setObject("USBLocationID", locationID);
    if (registryID) registryID->release();
    if (locationID) locationID->release();
    if (!prepared) {
        publishedBinding->release();
        return false;
    }
    publishedBinding->setOptions(OSCollection::kImmutable, OSCollection::kImmutable);
    const bool published = device->setProperty("DigitsDisplayBinding", publishedBinding);
    publishedBinding->release();
    if (published) {
        setProperty("DigitsDisplayBindingState", "Published");
        setProperty("PublishedPhysicalUSBRegistryID", device->getRegistryEntryID(), 64);
        IOLog("DigitsDriver: display binding published on physical USB registry ID %llu\n",
              device->getRegistryEntryID());
    }
    return published;
}
