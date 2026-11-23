// Initialize only our scalar identity before Apple's initialization can issue I/O.
#include "StringRequestInternals.hpp"

using namespace DigitsStringRequests;

bool XeneonStringDevice::initWithController(
    AppleUSBHostController* controller, UInt8 speed,
    tUSBHostDeviceAddress address)
{
    nativeIdentity_ = {};
    return IOUSBHostDevice::initWithController(controller, speed, address);
}
