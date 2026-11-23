#pragma once
#include <stdint.h>

namespace DigitsStringRequests {
constexpr uint16_t kEdgeVendor = 0x27c0;
constexpr uint16_t kEdgeProduct = 0x0859;
constexpr uint16_t kEdgeRevision = 0x0150;
constexpr uint16_t kStringReadCapacity = 255;
constexpr uint32_t kNativeDescriptorTimeoutMs = 5000;
constexpr uint16_t kDeviceDescriptorLength = 18;

// A scalar copy of a completed native DEVICE18 response, never a pointer into
// Apple's descriptor cache. It can be read inside an in-progress string read.
struct NativeDeviceIdentity {
    bool valid;
    uint16_t vendor;
    uint16_t product;
    uint16_t revision;
    uint8_t manufacturerIndex;
    uint8_t productIndex;
    uint8_t serialIndex;
};

// All multi-byte values here are host-endian. Native request/header bytes are
// decoded once at the kernel boundary; the policy itself has no device access.
struct StringRequestSelection {
    bool armed;
    bool nativeClient;
    uint16_t vendor;
    uint16_t product;
    uint16_t revision;
    uint8_t manufacturerIndex;
    uint8_t productIndex;
    uint8_t serialIndex;
    uint8_t requestType;
    uint8_t requestCode;
    uint16_t value;
    uint16_t language;
    uint16_t requestedLength;
    uint32_t timeoutMs;
};

bool qualifiesEnumerationStringRequest(const StringRequestSelection& selection);
uint32_t boundedStringCopyLength(uint32_t requestedLength, uint32_t transferredLength);
NativeDeviceIdentity snapshotCompletedDeviceDescriptor(
    const uint8_t* descriptor, uint32_t requestedLength,
    uint32_t transferredLength, bool requestSucceeded);
}
