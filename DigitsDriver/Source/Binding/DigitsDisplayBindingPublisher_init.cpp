#include "DigitsDisplayBindingPublisher.hpp"

bool DigitsDisplayBindingPublisher::init(OSDictionary* properties)
{
    binding_ = nullptr;
    deviceObserver_ = nullptr;
    // Normal IOKit personality initialization preserves the installer-supplied
    // dictionary. The hook's manually constructed control remains untouched.
    return IOService::init(properties);
}
