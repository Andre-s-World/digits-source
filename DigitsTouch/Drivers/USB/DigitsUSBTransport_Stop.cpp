#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::Stop_Impl(IOService *provider) {
    ReleaseResources();
    return Stop(provider, SUPERDISPATCH);
}
