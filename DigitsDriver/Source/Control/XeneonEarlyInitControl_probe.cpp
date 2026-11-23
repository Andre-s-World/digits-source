// The standard IOKit resource requests loading without claiming a USB controller.
#include "EarlyInitRuntime.hpp"

IOService* XeneonEarlyInitControl::probe(IOService*, SInt32*)
{
    // Module startup already created the sole resource-backed control service and
    // its observer. Declining probe prevents a second resource-backed control.
    return nullptr;
}
