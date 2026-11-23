// Tracks only the current thread stack; caller owns the short-held context lock.
#include "CreationContext.hpp"

void XeneonCreationContexts::pop(const Token& token)
{
    if (!token.valid || token.slot >= kThreadCount) return;
    Bucket& bucket = buckets_[token.slot];
    if (bucket.thread != token.thread) { bucket.blocked = true; return; }
    if (token.overflow) {
        if (bucket.overflow) --bucket.overflow;
        else bucket.blocked = true;
    } else if (bucket.overflow == 0 && bucket.depth == token.depth && bucket.depth != 0) {
        --bucket.depth;
        bucket.frames[bucket.depth] = {};
    } else {
        bucket.blocked = true; // Invalid unwinding cannot authorize a later claim.
    }
    if (!bucket.blocked && bucket.depth == 0 && bucket.overflow == 0) bucket.thread = 0;
}
