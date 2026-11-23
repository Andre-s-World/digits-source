#include "DigitsUSBTransportState.hpp"
void DigitsUSBTransport::ReleaseResources() {
    if (!ivars || ivars->stopping) return;
    IOLockLock(ivars->bindingLock);
    ivars->stopping = true;
    IOLockUnlock(ivars->bindingLock);
    if (ivars->digitizerPipe) {
        // Abort finishes this pipe's owned transfer before its DMA buffer can be released.
        ivars->digitizerPipe->Abort(kIOUSBAbortSynchronous, kIOReturnAborted, nullptr);
        ivars->readPending = false;
    }
    UnbindDisplay();
    // Provider termination owns child Stop ordering. Release our reference without
    // requesting nested termination while the USB provider is stopping.
    OSSafeReleaseNULL(ivars->touchDevice);
    if (ivars->interfaceOpen) {
        ivars->interface->Close(this, 0);
        ivars->interfaceOpen = false;
    }
    OSSafeReleaseNULL(ivars->digitizerPipe);
    OSSafeReleaseNULL(ivars->readCompletion);
    OSSafeReleaseNULL(ivars->interruptBuffer);
    OSSafeReleaseNULL(ivars->device);
    OSSafeReleaseNULL(ivars->interface);
}
