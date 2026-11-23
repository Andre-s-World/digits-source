// Sign a known table address using the measured controller-object PAC discriminator.
#include "PinnedControllerInternals.hpp"

namespace XeneonPinnedController {
uintptr_t signVptr(uintptr_t tableAddressPoint, uintptr_t controllerAddress)
{
    // Independently measured in the AppleT8142USBXHCI constructor: DA, object
    // address diversity, 0xcda1. No untrusted value is authenticated here.
    return reinterpret_cast<uintptr_t>(ptrauth_sign_unauthenticated(
        reinterpret_cast<void*>(tableAddressPoint), ptrauth_key_asda,
        ptrauth_blend_discriminator(reinterpret_cast<void*>(controllerAddress), 0xcda1)));
}
}
