#include "DigitsDisplayBindingPublisher.hpp"

bool DigitsDisplayBindingPublisher::devicePublished(
    void* target, void*, IOService* service, IONotifier*)
{
    auto* publisher = static_cast<DigitsDisplayBindingPublisher*>(target);
    if (publisher && service) publisher->publishToPhysicalDevice(service);
    return true;
}
