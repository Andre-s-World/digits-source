// Expand only the pinned native synchronous string request, preserving its caller.
#include "StringRequestInternals.hpp"

using namespace DigitsStringRequests;

IOReturn XeneonStringDevice::deviceRequest(
    IOService* client, StandardUSB::DeviceRequest& request, void* dataBuffer,
    uint32_t& bytesTransferred, uint32_t completionTimeoutMs)
{
    // Native DEVICE8/18 reads must remain unchanged. Save identity only after a
    // successful DEVICE18 return; no descriptor getter may be called here:
    // getDescriptorGated already owns its in-progress flag around this method.
    if (client == this && request.bmRequestType == 0x80 && request.bRequest == 0x06 &&
        OSSwapLittleToHostInt16(request.wValue) == 0x0100 &&
        OSSwapLittleToHostInt16(request.wIndex) == 0 &&
        completionTimeoutMs == kNativeDescriptorTimeoutMs) {
        const IOReturn status = IOUSBHostDevice::deviceRequest(
            client, request, dataBuffer, bytesTransferred, completionTimeoutMs);
        const NativeDeviceIdentity completedIdentity = snapshotCompletedDeviceDescriptor(
            static_cast<const uint8_t*>(dataBuffer),
            OSSwapLittleToHostInt16(request.wLength), bytesTransferred,
            status == kIOReturnSuccess);
        if (completedIdentity.valid) {
            nativeIdentity_ = completedIdentity;
            IOLog("DigitsDriver: native DEVICE18 identity captured %04x:%04x "
                  "revision=%04x string-indices=%u/%u/%u\n",
                  static_cast<unsigned>(nativeIdentity_.vendor),
                  static_cast<unsigned>(nativeIdentity_.product),
                  static_cast<unsigned>(nativeIdentity_.revision),
                  static_cast<unsigned>(nativeIdentity_.manufacturerIndex),
                  static_cast<unsigned>(nativeIdentity_.productIndex),
                  static_cast<unsigned>(nativeIdentity_.serialIndex));
        }
        return status;
    }

    if (!XeneonEarlyInitRequestsEnabled() || client != this ||
        request.bmRequestType != 0x80 || request.bRequest != 0x06 ||
        (OSSwapLittleToHostInt16(request.wValue) >> 8) != 0x03 || !nativeIdentity_.valid) {
        return IOUSBHostDevice::deviceRequest(
            client, request, dataBuffer, bytesTransferred, completionTimeoutMs);
    }
    const StringRequestSelection selection{
        XeneonEarlyInitRequestsEnabled(), client == this,
        nativeIdentity_.vendor, nativeIdentity_.product, nativeIdentity_.revision,
        nativeIdentity_.manufacturerIndex, nativeIdentity_.productIndex,
        nativeIdentity_.serialIndex,
        request.bmRequestType, request.bRequest,
        OSSwapLittleToHostInt16(request.wValue),
        OSSwapLittleToHostInt16(request.wIndex),
        OSSwapLittleToHostInt16(request.wLength), completionTimeoutMs
    };
    if (!qualifiesEnumerationStringRequest(selection) ||
        !XeneonEarlyInitHasPinnedTopology(this)) {
        return IOUSBHostDevice::deviceRequest(
            client, request, dataBuffer, bytesTransferred, completionTimeoutMs);
    }
    bytesTransferred = 0;
    if (dataBuffer == nullptr) {
        return kIOReturnBadArgument; // A qualified request must never fall back short.
    }
    XeneonEarlyInitRecordQualifiedString();

    // Both setup and data storage remain local until the synchronous base call
    // completes. In particular, the native two-byte allocation is never passed
    // to a 255-byte transfer, and its caller-owned setup is not modified.
    StandardUSB::DeviceRequest expandedRequest = request;
    expandedRequest.wLength = OSSwapHostToLittleInt16(kStringReadCapacity);
    uint8_t expandedBuffer[kStringReadCapacity] = {};
    uint32_t expandedTransferred = 0;
    const IOReturn status = IOUSBHostDevice::deviceRequest(
        client, expandedRequest, static_cast<void*>(expandedBuffer),
        expandedTransferred, completionTimeoutMs);

    // Preserve partial data and the actual base status, including failed I/O.
    // Apple's native getter still validates descriptors, owns its workloop gate,
    // manages the in-progress flag, and decides when to retry or cache data.
    const uint32_t copyLength = boundedStringCopyLength(
        selection.requestedLength, expandedTransferred);
    if (copyLength != 0) {
        memcpy(dataBuffer, expandedBuffer, copyLength);
    }
    bytesTransferred = copyLength;
    IOLog("DigitsDriver: string index=%u lang=0x%04x requested=%u expanded=255 "
          "status=0x%08x transferred=%u returned=%u\n",
          static_cast<unsigned>(selection.value & 0xff),
          static_cast<unsigned>(selection.language),
          static_cast<unsigned>(selection.requestedLength),
          static_cast<unsigned>(status), static_cast<unsigned>(expandedTransferred),
          static_cast<unsigned>(copyLength));
    return status;
}
