// Limit the quirk to measured native enumeration requests on this exact device.
#include "StringRequestPolicy.hpp"

namespace DigitsStringRequests {
bool qualifiesEnumerationStringRequest(const StringRequestSelection& selection)
{
    if (!selection.armed || !selection.nativeClient ||
        selection.vendor != kEdgeVendor || selection.product != kEdgeProduct ||
        selection.revision != kEdgeRevision || selection.requestType != 0x80 ||
        selection.requestCode != 0x06 || (selection.value >> 8) != 0x03 ||
        selection.requestedLength < 2 || selection.requestedLength > kStringReadCapacity ||
        selection.timeoutMs != kNativeDescriptorTimeoutMs) {
        return false;
    }

    const uint8_t index = static_cast<uint8_t>(selection.value);
    if (index == 0) {
        return selection.language == 0; // USB language-ID table.
    }
    const bool declaredString = index == selection.manufacturerIndex ||
        index == selection.productIndex || index == selection.serialIndex;
    return declaredString && selection.language == 0x0409;
}
}
