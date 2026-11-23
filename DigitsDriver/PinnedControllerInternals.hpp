#pragma once
// Preparation only: no loader, USB operation, publication, CAS, or vptr store.
#include "PinnedControllerShadow.hpp"
#include "PinnedControllerTable.generated.hpp"
#ifdef XENEON_SDK27_COMPILE_ONLY_PM_TYPES
#include "sdk27-pm-types-compile-only.h"
#endif
#include <IOKit/IOService.h>
#include <IOKit/IOLib.h>
#include <IOKit/usb/IOUSBHostDevice.h>
#include <libkern/version.h>
#include <ptrauth.h>

#if !defined(__arm64e__) || !__has_feature(ptrauth_intrinsics)
#error "An arm64e kernel ABI with real PAC intrinsics is required."
#endif


namespace XeneonPinnedController {
static_assert(sizeof(uintptr_t) == 8, "64-bit kernel ABI required");
static_assert(Data::kFunctionCount == 439 && Data::kTableBytes == 0xdd0,
              "Unexpected pinned leaf table extent");
bool addSlide(uintptr_t, uintptr_t, uintptr_t*);
bool validUnsignedCodeAddress(uintptr_t);
uintptr_t signEntry(uintptr_t, uintptr_t, uint16_t);
uintptr_t signVptr(uintptr_t, uintptr_t);
}
