#include "DigitsDisplayBindingPublisher.hpp"

bool DigitsDisplayBindingPublisher::observePhysicalDevices()
{
    auto* matching = IOService::serviceMatching("IOUSBHostDevice");
    if (!matching) return false;
    // First-publish callbacks also cover already published devices. This is an
    // observation only; it does not compete with USB interface driver matching.
    deviceObserver_ = IOService::addMatchingNotification(
        gIOFirstPublishNotification, matching, &devicePublished, this, nullptr, 0);
    matching->release();
    return deviceObserver_ != nullptr;
}
