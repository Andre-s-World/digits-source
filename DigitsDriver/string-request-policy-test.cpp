// Offline policy/buffer contract only. This executable never links IOKit or USB.
#include "StringRequestPolicy.hpp"
#include <assert.h>
#include <initializer_list>
#include <stdio.h>
#include <string.h>

using namespace DigitsStringRequests;

int main()
{
    const uint8_t nativeDeviceDescriptor[kDeviceDescriptorLength] = {
        18, 1, 0x00, 0x02, 0, 0, 0, 64, 0xc0, 0x27, 0x59, 0x08,
        0x50, 0x01, 1, 2, 3, 1
    };
    NativeDeviceIdentity identity = snapshotCompletedDeviceDescriptor(
        nativeDeviceDescriptor, 18, 18, true);
    assert(identity.valid && identity.vendor == kEdgeVendor);
    assert(identity.product == kEdgeProduct && identity.revision == kEdgeRevision);
    assert(identity.manufacturerIndex == 1 && identity.productIndex == 2 &&
           identity.serialIndex == 3);
    // The first eight-byte native read must neither authorize strings nor read
    // beyond that small caller allocation. Failed/truncated/malformed data is inert.
    const uint8_t firstDeviceBytes[8] = {18, 1, 0x00, 0x02, 0, 0, 0, 64};
    assert(!snapshotCompletedDeviceDescriptor(firstDeviceBytes, 8, 8, true).valid);
    assert(!snapshotCompletedDeviceDescriptor(nativeDeviceDescriptor, 18, 8, true).valid);
    assert(!snapshotCompletedDeviceDescriptor(nativeDeviceDescriptor, 18, 18, false).valid);
    assert(!snapshotCompletedDeviceDescriptor(nullptr, 18, 18, true).valid);
    assert(!snapshotCompletedDeviceDescriptor(nativeDeviceDescriptor, 18, 19, true).valid);
    uint8_t malformedDescriptor[kDeviceDescriptorLength];
    memcpy(malformedDescriptor, nativeDeviceDescriptor, sizeof(malformedDescriptor));
    malformedDescriptor[1] = 3;
    assert(!snapshotCompletedDeviceDescriptor(malformedDescriptor, 18, 18, true).valid);

    StringRequestSelection selection{
        true, true, identity.vendor, identity.product, identity.revision,
        identity.manufacturerIndex, identity.productIndex, identity.serialIndex,
        0x80, 0x06, 0x0302, 0x0409, 2, 5000
    };
    assert(qualifiesEnumerationStringRequest(selection));
    for (const uint16_t length : {uint16_t(2), uint16_t(14), uint16_t(24),
                                  uint16_t(28), uint16_t(255)}) {
        selection.requestedLength = length;
        assert(qualifiesEnumerationStringRequest(selection));
    }
    selection.requestedLength = 2;
    const StringRequestSelection original = selection;
    selection.armed = false;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection = original;
    selection.nativeClient = false;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection = original;
    selection.vendor = 0x27c6;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection = original;
    selection.revision = 0x0110;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection = original;
    selection.value = 0x0304;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection.value = 0x0300;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection.language = 0;
    assert(qualifiesEnumerationStringRequest(selection));
    selection = original;
    selection.language = 0;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection = original;
    selection.value = 0x0100;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection = original;
    selection.requestType = 0xa1;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection = original;
    selection.requestCode = 0x09;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection = original;
    selection.requestedLength = 256;
    assert(!qualifiesEnumerationStringRequest(selection));
    selection = original;
    selection.timeoutMs = 0;
    assert(!qualifiesEnumerationStringRequest(selection));

    uint8_t source[kStringReadCapacity];
    memset(source, 0x5a, sizeof(source));
    uint8_t destination[6];
    memset(destination, 0xcc, sizeof(destination));
    const uint32_t copyLength = boundedStringCopyLength(2, 24);
    memcpy(destination + 2, source, copyLength);
    assert(copyLength == 2 && destination[0] == 0xcc && destination[1] == 0xcc);
    assert(destination[2] == 0x5a && destination[3] == 0x5a);
    assert(destination[4] == 0xcc && destination[5] == 0xcc);
    assert(boundedStringCopyLength(24, 14) == 14);
    assert(boundedStringCopyLength(24, 0) == 0);
    assert(boundedStringCopyLength(255, 256) == 255);
    assert(boundedStringCopyLength(2, 1) == 1);
    puts("PASS: complete DEVICE18 identity, rejected DEVICE8/failures, exact string "
         "selection, two-byte buffer guards, partial/oversize bounds");
}
