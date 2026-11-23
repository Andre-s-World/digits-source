// Allocate the actual derived object and preserve the base factory ownership sequence.
#include "StringRequestInternals.hpp"

using namespace DigitsStringRequests;

XeneonStringDevice* XeneonStringDevice::withController(
    AppleUSBHostController* controller, UInt8 speed,
    tUSBHostDeviceAddress address)
{
    auto* device = new XeneonStringDevice;
    if (device != nullptr &&
        !device->initWithController(controller, speed, address)) {
        device->release();
        device = nullptr;
    }
    return device;
}
