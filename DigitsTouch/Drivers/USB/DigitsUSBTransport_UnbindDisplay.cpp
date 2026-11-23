#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::UnbindDisplay() {
    IOLockLock(ivars->bindingLock);
    ivars->displayBound = false;
    ++ivars->bindingGeneration;
    memset(&ivars->binding, 0, sizeof(ivars->binding));
    IOLockUnlock(ivars->bindingLock);
    if (ivars->touchDevice) {
        ivars->touchDevice->LiftAllContacts();
        // Closing the configuration app pauses forwarding. The HID device belongs to the
        // USB connection, not to an app window; retaining it prevents stop/create churn.
    }
    return PublishIdentity(ivars->stopping ? "Stopping" : "Unbound");
}
