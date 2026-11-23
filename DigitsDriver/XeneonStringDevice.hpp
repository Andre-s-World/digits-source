#pragma once

#ifdef XENEON_SDK27_COMPILE_ONLY_PM_TYPES
#include "sdk27-pm-types-compile-only.h"
#endif
#include <IOKit/usb/IOUSBHostDevice.h>
#include "StringRequestPolicy.hpp"

// The scoped factory allocates a real derived object before identification.
// The legacy class name is retained because this test changes the request seam,
// not the pinned controller or metaclass ABI.
class XeneonStringDevice : public IOUSBHostDevice {
    OSDeclareDefaultStructors(XeneonStringDevice)

public:
    static XeneonStringDevice* withController(
        AppleUSBHostController* controller, UInt8 speed,
        tUSBHostDeviceAddress address);

    using IOUSBHostDevice::deviceRequest;
    IOReturn deviceRequest(
        IOService* client, StandardUSB::DeviceRequest& request, void* dataBuffer,
        uint32_t& bytesTransferred, uint32_t completionTimeoutMs) override;

protected:
    bool initWithController(AppleUSBHostController* controller, UInt8 speed,
                            tUSBHostDeviceAddress address) override;

private:
    DigitsStringRequests::NativeDeviceIdentity nativeIdentity_;
};
