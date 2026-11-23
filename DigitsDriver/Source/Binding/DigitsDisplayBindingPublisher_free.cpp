#include "DigitsDisplayBindingPublisher.hpp"

void DigitsDisplayBindingPublisher::free()
{
    if (deviceObserver_) {
        deviceObserver_->remove();
        deviceObserver_ = nullptr;
    }
    if (binding_) {
        binding_->release();
        binding_ = nullptr;
    }
    IOService::free();
}
