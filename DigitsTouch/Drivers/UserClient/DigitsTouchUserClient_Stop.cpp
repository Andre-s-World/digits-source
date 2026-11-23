#include "DigitsTouchUserClientState.hpp"
kern_return_t DigitsTouchUserClient::Stop_Impl(IOService *provider) {
    // Closing/crashing the metadata host removes the association and lifts existing contacts.
    if (ivars->transport) {
        ivars->transport->CloseMetadataClient();
        OSSafeReleaseNULL(ivars->transport);
    }
    return Stop(provider, SUPERDISPATCH);
}
