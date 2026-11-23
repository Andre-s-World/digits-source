// Capture only the complete fixed-size USB device descriptor, never DEVICE8.
#include "StringRequestPolicy.hpp"

namespace DigitsStringRequests {
NativeDeviceIdentity snapshotCompletedDeviceDescriptor(
    const uint8_t* descriptor, uint32_t requestedLength,
    uint32_t transferredLength, bool requestSucceeded)
{
    NativeDeviceIdentity identity{};
    if (!requestSucceeded || descriptor == nullptr ||
        requestedLength != kDeviceDescriptorLength ||
        transferredLength != kDeviceDescriptorLength ||
        descriptor[0] != kDeviceDescriptorLength || descriptor[1] != 0x01) {
        return identity;
    }

    identity.vendor = static_cast<uint16_t>(descriptor[8] | (descriptor[9] << 8));
    identity.product = static_cast<uint16_t>(descriptor[10] | (descriptor[11] << 8));
    identity.revision = static_cast<uint16_t>(descriptor[12] | (descriptor[13] << 8));
    identity.manufacturerIndex = descriptor[14];
    identity.productIndex = descriptor[15];
    identity.serialIndex = descriptor[16];
    identity.valid = true;
    return identity;
}
}
