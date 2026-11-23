// Tracks only the current thread stack; caller owns the short-held context lock.
#include "CreationContext.hpp"

bool XeneonCreationContexts::claim(uintptr_t thread, uintptr_t controller, uint32_t speed,
           uint32_t options, uint32_t wantedRoute)
{
    for (size_t bucketIndex = 0; bucketIndex < kThreadCount; ++bucketIndex) {
        Bucket& bucket = buckets_[bucketIndex];
        if (bucket.thread != thread) continue;
        if (bucket.blocked || bucket.overflow || bucket.depth == 0) return false;
        Frame& frame = bucket.frames[bucket.depth - 1];
        if (frame.consumed || frame.controller != controller ||
            frame.route != wantedRoute || frame.speed != speed ||
            frame.options != options || (options & 1u) != 0) return false;
        frame.consumed = true;
        return true;
    }
    return false;
}
