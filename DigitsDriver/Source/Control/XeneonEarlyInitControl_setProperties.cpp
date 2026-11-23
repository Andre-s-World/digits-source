// Validate administrator privilege and explicit acknowledgement before dispatching an action.
#include "EarlyInitRuntime.hpp"

using namespace DigitsEarlyInit;

IOReturn XeneonEarlyInitControl::setProperties(OSObject* properties)
{
    if (IOUserClient::clientHasPrivilege(current_task(),
            kIOClientPrivilegeAdministrator) != kIOReturnSuccess)
        return kIOReturnNotPrivileged;
    auto* dictionary = OSDynamicCast(OSDictionary, properties);
    if (!dictionary || dictionary->getCount() != 2) return kIOReturnBadArgument;
    auto* action = OSDynamicCast(OSString, dictionary->getObject("Action"));
    auto* acknowledgement = OSDynamicCast(OSString,
                                        dictionary->getObject("Acknowledgement"));
    if (!action || !acknowledgement ||
        !acknowledgement->isEqualTo(kAcknowledgement)) return kIOReturnBadArgument;
    IOLockLock(driverRuntime.controlLock);
    IOReturn status = kIOReturnBadArgument;
    if (action->isEqualTo("arm")) status = arm();
    else if (action->isEqualTo("disarm")) status = disarm();
    else if (action->isEqualTo("status")) status = kIOReturnSuccess;
    publishStatus();
    IOLockUnlock(driverRuntime.controlLock);
    return status;
}
