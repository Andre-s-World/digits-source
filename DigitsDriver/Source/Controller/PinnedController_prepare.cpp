// Validate every pinned kernel/table byte before allocating an unpublished shadow table.
#include "PinnedControllerInternals.hpp"

namespace XeneonPinnedController {
Status prepare(IOService* controller, uintptr_t outerCallback,
               uintptr_t innerCallback, PreparedShadow* preparedShadow)
{
    if (preparedShadow == nullptr)
        return Status::InvalidArgument;
    if (preparedShadow->allocation != nullptr)
        return Status::OutputNotEmpty;
    *preparedShadow = {};
    const uintptr_t controllerAddress = reinterpret_cast<uintptr_t>(controller);
    if (controllerAddress == 0 || (controllerAddress & 7) != 0 ||
        !validUnsignedCodeAddress(outerCallback) ||
        !validUnsignedCodeAddress(innerCallback))
        return Status::InvalidArgument;

    // version[] is a public exported kernel string. Compare all pinned bytes,
    // including NUL, before any private object/table interpretation. No uname,
    // filesystem, collection parsing, or process interface is used at runtime.
    for (size_t entryIndex = 0; entryIndex < sizeof(Data::kKernelVersion); ++entryIndex) {
        if (version[entryIndex] != Data::kKernelVersion[entryIndex])
            return Status::KernelVersionMismatch;
    }

    const uintptr_t metaclassAddress = reinterpret_cast<uintptr_t>(&IOUSBHostDevice::gMetaClass);
    if (metaclassAddress < Data::kAnchorUnslid)
        return Status::InvalidSlide;
    const uintptr_t collectionSlide = metaclassAddress - Data::kAnchorUnslid;
    if ((collectionSlide & 0xfff) != 0)
        return Status::InvalidSlide;
    uintptr_t expectedVersion = 0;
    uintptr_t originalTableAddress = 0;
    if (!addSlide(Data::kVersionUnslid, collectionSlide, &expectedVersion) ||
        expectedVersion != reinterpret_cast<uintptr_t>(version))
        return Status::AnchorMismatch;
    if (!addSlide(Data::kTableUnslid, collectionSlide, &originalTableAddress) ||
        originalTableAddress > UINTPTR_MAX - Data::kTableBytes)
        return Status::InvalidSlide;

    // Compare the raw first word against a freshly signed KNOWN table address
    // before dereferencing any table. Never autda/autia a caller-supplied vptr.
    const uintptr_t originalVptr =
        *reinterpret_cast<const volatile uintptr_t*>(controllerAddress);
    const uintptr_t expectedVptr = signVptr(originalTableAddress + 2 * sizeof(uintptr_t), controllerAddress);
    if (originalVptr != expectedVptr)
        return Status::ControllerVptrMismatch;

    const volatile uintptr_t* const originalTable =
        reinterpret_cast<const volatile uintptr_t*>(originalTableAddress);
    if (originalTable[0] != 0 || originalTable[1] != 0 ||
        originalTable[Data::kTableWords - 1] != 0)
        return Status::TableLayoutMismatch;
    for (size_t entryIndex = 0; entryIndex < Data::kFunctionCount; ++entryIndex) {
        uintptr_t targetAddress = 0;
        if (!addSlide(Data::kEntries[entryIndex].targetUnslid, collectionSlide, &targetAddress))
            return Status::InvalidSlide;
        const uintptr_t slotAddress = originalTableAddress + (Data::kHeaderWords + entryIndex) * sizeof(uintptr_t);
        const uintptr_t expected = signEntry(targetAddress, slotAddress, Data::kEntries[entryIndex].diversity);
        if (originalTable[Data::kHeaderWords + entryIndex] != expected)
            return Status::TableEntryMismatch;
    }

    void* const allocation = IOMallocAligned(Data::kTableBytes, 16);
    if (allocation == nullptr)
        return Status::NoMemory;
    uintptr_t* const shadowTable = reinterpret_cast<uintptr_t*>(allocation);
    shadowTable[0] = shadowTable[1] = shadowTable[Data::kTableWords - 1] = 0;
    for (size_t entryIndex = 0; entryIndex < Data::kFunctionCount; ++entryIndex) {
        // The complete source table has already passed validation. addSlide
        // cannot now fail for these unchanged inputs.
        uintptr_t targetAddress = Data::kEntries[entryIndex].targetUnslid + collectionSlide;
        if (entryIndex == Data::kOuterIndex)
            targetAddress = outerCallback;
        else if (entryIndex == Data::kInnerIndex)
            targetAddress = innerCallback;
        const uintptr_t slotAddress = reinterpret_cast<uintptr_t>(&shadowTable[Data::kHeaderWords + entryIndex]);
        shadowTable[Data::kHeaderWords + entryIndex] = signEntry(targetAddress, slotAddress, Data::kEntries[entryIndex].diversity);
    }
    preparedShadow->allocation = allocation;
    preparedShadow->bytes = Data::kTableBytes;
    preparedShadow->originalSignedVptr = originalVptr;
    preparedShadow->newSignedVptr = signVptr(reinterpret_cast<uintptr_t>(&shadowTable[Data::kHeaderWords]), controllerAddress);
    preparedShadow->unsignedOriginalOuter = Data::kEntries[Data::kOuterIndex].targetUnslid + collectionSlide;
    preparedShadow->unsignedOriginalInner = Data::kEntries[Data::kInnerIndex].targetUnslid + collectionSlide;
    preparedShadow->collectionSlide = collectionSlide;
    return Status::OK;
}
}
