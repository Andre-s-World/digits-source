#include "DigitsTouchUserClientState.hpp"
bool DigitsTouchUserClient::init() {
    if (!super::init()) return false;
    ivars = IONewZero(DigitsTouchUserClient_IVars, 1);
    return ivars != nullptr;
}
