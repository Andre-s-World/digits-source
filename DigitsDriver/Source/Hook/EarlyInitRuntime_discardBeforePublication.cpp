// Release preparation resources only before any callable hook has been published.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
void discardBeforePublication()
{
    if (driverRuntime.everPublished) return;
    XeneonPinnedController::discardUnpublished(&driverRuntime.shadow);
    if (driverRuntime.workLoop) { driverRuntime.workLoop->release(); driverRuntime.workLoop = nullptr; }
    if (driverRuntime.controller) { driverRuntime.controller->release(); driverRuntime.controller = nullptr; }
    driverRuntime.originalOuterFactory = nullptr;
    driverRuntime.originalInnerFactory = nullptr;
    if (driverRuntime.pinned) { OSKextReleaseKextWithLoadTag(driverRuntime.loadTag); driverRuntime.pinned = false; }
}
}
