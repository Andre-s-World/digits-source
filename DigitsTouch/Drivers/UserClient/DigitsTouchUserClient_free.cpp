#include "DigitsTouchUserClientState.hpp"
void DigitsTouchUserClient::free() {
    if (ivars) {
        OSSafeReleaseNULL(ivars->transport);
        IODelete(ivars, DigitsTouchUserClient_IVars, 1);
        ivars = nullptr;
    }
    super::free();
}
