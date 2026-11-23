// Syntax/object probe compatibility only. Not a deployment ABI assertion.
// These three exact typedefs are from Apple's installed MacOSX26.5.sdk:
// Kernel.framework/Versions/A/Headers/IOKit/pwr_mgt/RootDomain.h:48,56,63.
// The local SDK27.0/27.2 headers reference but omit these definitions.
#pragma once
#include <stdint.h>
typedef uint64_t IOPMDriverAssertionType;
typedef uint64_t IOPMDriverAssertionID;
typedef uint32_t IOPMDriverAssertionLevel;
