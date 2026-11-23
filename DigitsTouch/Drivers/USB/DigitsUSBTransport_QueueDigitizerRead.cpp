#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::QueueDigitizerRead() {
    if (ivars->stopping || !ivars->descriptorValidated || !ivars->digitizerPipe ||
        !ivars->readCompletion) return kIOReturnNotReady;
    if (ivars->readPending) return kIOReturnBusy;
    // A timeout of zero is required for interrupt AsyncIO. There is exactly one owned read.
    const kern_return_t result = ivars->digitizerPipe->AsyncIO(
        ivars->interruptBuffer, DigitsUSB::InterruptCapacity, ivars->readCompletion, 0);
    ivars->readPending = result == kIOReturnSuccess;
    return result;
}
