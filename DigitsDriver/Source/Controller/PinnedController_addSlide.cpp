// Reject address arithmetic overflow before interpreting a slid kernel address.
#include "PinnedControllerInternals.hpp"

namespace XeneonPinnedController {
bool addSlide(uintptr_t unslid, uintptr_t collectionSlide, uintptr_t* result)
{
    if (unslid > UINTPTR_MAX - collectionSlide)
        return false;
    *result = unslid + collectionSlide;
    return true;
}
}
