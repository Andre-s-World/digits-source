#include "DigitsDisplayBindingPublisher.hpp"

void DigitsDisplayBindingPublisher::stop(IOService* provider)
{
    // Remove notification delivery before releasing configuration in free().
    // Published metadata contains only standard OS collection/string/number
    // objects, and may safely remain until the physical USB entry terminates.
    if (deviceObserver_) {
        deviceObserver_->remove();
        deviceObserver_ = nullptr;
    }
    IOService::stop(provider);
}
