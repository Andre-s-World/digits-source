#include "DigitsUSBTransportState.hpp"
void DigitsUSBTransport::CloseMetadataClient() {
    ivars->metadataClientOpen = false;
    // A configuration connection does not own the physical input lifetime.
    // Keep the validated binding when Digits closes; provider Stop clears it.
}
