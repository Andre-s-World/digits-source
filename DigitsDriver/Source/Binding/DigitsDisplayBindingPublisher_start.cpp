#include "DigitsDisplayBindingPublisher.hpp"
#include <IOKit/IOLib.h>

bool DigitsDisplayBindingPublisher::start(IOService* provider)
{
    if (!IOService::start(provider)) return false;

    auto* configured = copyProperty("DigitsDisplayBinding");
    auto* dictionary = OSDynamicCast(OSDictionary, configured);
    if (!configured) {
        setProperty("DigitsDisplayBindingState", "Unconfigured");
    } else if (!dictionary || !validateBinding(dictionary)) {
        // Invalid or missing configuration must not prevent the independent
        // early driver and Digits Touch transport from loading.
        setProperty("DigitsDisplayBindingState", "InvalidConfiguration");
        IOLog("DigitsDriver: display binding configuration rejected; no USB metadata published\n");
    } else {
        binding_ = OSDictionary::withDictionary(dictionary);
        if (!binding_) {
            setProperty("DigitsDisplayBindingState", "AllocationFailed");
        } else {
            binding_->setOptions(OSCollection::kImmutable, OSCollection::kImmutable);
            setProperty("DigitsDisplayBindingState", "WaitingForPhysicalDevice");
            if (!observePhysicalDevices()) {
                setProperty("DigitsDisplayBindingState", "ObserverUnavailable");
            }
        }
    }
    if (configured) configured->release();
    registerService();
    return true;
}
