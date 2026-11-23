#include "DigitsTouchUserClientState.hpp"
kern_return_t DigitsTouchUserClient::Start_Impl(IOService *provider) {
    kern_return_t result = Start(provider, SUPERDISPATCH);
    if (result != kIOReturnSuccess) return result;
    ivars->transport = OSDynamicCast(DigitsUSBTransport, provider);
    if (!ivars->transport) return kIOReturnUnsupported;
    ivars->transport->retain();
    return kIOReturnSuccess;
}
