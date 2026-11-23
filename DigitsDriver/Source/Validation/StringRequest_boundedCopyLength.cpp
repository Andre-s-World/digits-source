// Never expose the expanded transfer size as the native caller's buffer size.
#include "StringRequestPolicy.hpp"

namespace DigitsStringRequests {
uint32_t boundedStringCopyLength(uint32_t requestedLength, uint32_t transferredLength)
{
    uint32_t copyLength = transferredLength < kStringReadCapacity
        ? transferredLength : kStringReadCapacity;
    if (copyLength > requestedLength) {
        copyLength = requestedLength;
    }
    return copyLength;
}
}
