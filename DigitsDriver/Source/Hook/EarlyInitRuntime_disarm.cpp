// Stop selecting devices while retaining every published resource until reboot.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
IOReturn disarm()
{
    if (!driverRuntime.everPublished) return kIOReturnNotReady;
    if (!driverRuntime.hookInstalled) return kIOReturnSuccess;
    const auto status = driverRuntime.workLoop->runAction(&disableAction, driverRuntime.controller);
    driverRuntime.state = status == kIOReturnSuccess ? "disarmed-retained-until-reboot" :
                                          "disabled-vptr-not-restored";
    IOLog("XeneonInit: disarm status=0x%08x; no published resources freed\n",
          static_cast<unsigned>(status));
    return status;
}
}
