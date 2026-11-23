// Tracks only the current thread stack; caller owns the short-held context lock.
#include "CreationContext.hpp"

XeneonCreationContexts::Token XeneonCreationContexts::push(uintptr_t thread, uintptr_t controller, uint32_t speed,
           uint32_t route, uint32_t options)
{
    if (thread == 0 || controller == 0) return {};
    size_t slot = kThreadCount;
    size_t empty = kThreadCount;
    for (size_t bucketIndex = 0; bucketIndex < kThreadCount; ++bucketIndex) {
        if (buckets_[bucketIndex].thread == thread) { slot = bucketIndex; break; }
        if (buckets_[bucketIndex].thread == 0 && empty == kThreadCount) empty = bucketIndex;
    }
    if (slot == kThreadCount) slot = empty;
    if (slot == kThreadCount) return {}; // No existing frame for this thread.
    Bucket& bucket = buckets_[slot];
    if (bucket.thread == 0) bucket.thread = thread;
    if (bucket.blocked || bucket.overflow != 0 || bucket.depth == kDepth) {
        if (bucket.overflow == UINT32_MAX) bucket.blocked = true;
        else ++bucket.overflow;
        return {thread, static_cast<uint32_t>(slot), bucket.depth, true, true};
    }
    bucket.frames[bucket.depth++] = {controller, speed, route, options, false};
    return {thread, static_cast<uint32_t>(slot), bucket.depth, false, true};
}
