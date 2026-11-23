// Free only preparation memory that has never been visible to a controller.
#include "PinnedControllerInternals.hpp"

namespace XeneonPinnedController {
void discardUnpublished(PreparedShadow* shadowTable)
{
    if (shadowTable == nullptr)
        return;
    if (shadowTable->allocation != nullptr)
        IOFreeAligned(shadowTable->allocation, shadowTable->bytes);
    *shadowTable = {};
}
}
