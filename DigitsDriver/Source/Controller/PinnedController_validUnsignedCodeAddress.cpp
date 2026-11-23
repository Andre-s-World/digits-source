// Reject null, unaligned, or still-signed callback addresses before table preparation.
#include "PinnedControllerInternals.hpp"

namespace XeneonPinnedController {
bool validUnsignedCodeAddress(uintptr_t address)
{
    // Provenance and the exact callback ABI remain the caller's obligation.
    // The arithmetic check also catches ordinary still-signed function values.
    return address != 0 && (address & 3) == 0 && (address >> 48) == 0xffff;
}
}
