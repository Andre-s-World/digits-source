#pragma once
#include <stddef.h>
#include <stdint.h>

class IOService;

namespace XeneonPinnedController {

enum class Status {
    OK = 0,
    InvalidArgument,
    OutputNotEmpty,
    KernelVersionMismatch,
    AnchorMismatch,
    InvalidSlide,
    ControllerVptrMismatch,
    TableLayoutMismatch,
    TableEntryMismatch,
    NoMemory
};

struct PreparedShadow {
    void* allocation;
    size_t bytes;
    uintptr_t originalSignedVptr;
    uintptr_t newSignedVptr;
    uintptr_t unsignedOriginalOuter;
    uintptr_t unsignedOriginalInner;
    uintptr_t collectionSlide;
};

// The caller supplies a retained, identity-checked live IOService and verified
// UNSIGNED arm64e code addresses with the exact outer/inner factory ABIs. This
// function only reads that object's first word and the known original table.
// It never authenticates untrusted pointers, calls the callbacks, changes an
// object, publishes the shadow, or retains/releases the controller.
//
// Initialize *out to {}. On success, ownership of the allocation passes to the
// caller. On failure no allocation is left owned by *out. The original method
// addresses are UNSIGNED; the caller must sign them for the exact C function
// pointer type before invoking them. No arbitrary function-pointer cast is a
// substitute for that ABI conversion.
Status prepare(IOService* controller, uintptr_t unsignedOuterCallback,
               uintptr_t unsignedInnerCallback, PreparedShadow* out);

// ONLY for an allocation that has never been published to any controller.
// After publication, the caller owns the boot-long lifetime; this function
// cannot establish quiescence and must never be used as a runtime undo path.
void discardUnpublished(PreparedShadow* shadow);

const char* statusName(Status status);

} // namespace XeneonPinnedController
