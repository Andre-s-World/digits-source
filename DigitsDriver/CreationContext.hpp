#pragma once
#include <stddef.h>
#include <stdint.h>

// The caller supplies a short-held lock around every method. No OS calls,
// allocations, callbacks, or waits occur here. A synchronous factory call keeps
// its thread alive until its matching pop; thread keys are never retained after
// the last frame. Nested overflow suppresses selection instead of exposing a
// parent's route to an unrelated nested creation.
class XeneonCreationContexts {
public:
    static constexpr size_t kThreadCount = 32;
    static constexpr size_t kDepth = 8;
    struct Frame {
        uintptr_t controller;
        uint32_t speed;
        uint32_t route;
        uint32_t options;
        bool consumed;
    };
    struct Token {
        uintptr_t thread;
        uint32_t slot;
        uint32_t depth;
        bool overflow;
        bool valid;
    };

    Token push(uintptr_t thread, uintptr_t controller, uint32_t speed,
               uint32_t route, uint32_t options);

    bool claim(uintptr_t thread, uintptr_t controller, uint32_t speed,
               uint32_t options, uint32_t wantedRoute);

    void pop(const Token& token);

private:
    struct Bucket {
        uintptr_t thread;
        uint32_t depth;
        uint32_t overflow;
        bool blocked;
        Frame frames[kDepth];
    };
    Bucket buckets_[kThreadCount]{};
};
