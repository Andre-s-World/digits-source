// Sign each callback for its destination slot and measured PAC discriminator.
#include "PinnedControllerInternals.hpp"

namespace XeneonPinnedController {
uintptr_t signEntry(uintptr_t targetAddress, uintptr_t slotAddress, uint16_t diversity)
{
    const ptrauth_extra_data_t discriminator = diversity == 0
        ? static_cast<ptrauth_extra_data_t>(slotAddress)
        : ptrauth_blend_discriminator(reinterpret_cast<void*>(slotAddress), diversity);
    return reinterpret_cast<uintptr_t>(ptrauth_sign_unauthenticated(
        reinterpret_cast<void*>(targetAddress), ptrauth_key_asia, discriminator));
}
}
