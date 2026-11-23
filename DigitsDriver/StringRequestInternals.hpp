#pragma once
#include "XeneonStringDevice.hpp"
#include "StringRequestPolicy.hpp"
#include <IOKit/IOLib.h>
#include <libkern/OSByteOrder.h>
#include <libkern/libkern.h>

// Supplied by the integrator as an atomic read of its armed/accepting state.
extern "C" bool XeneonEarlyInitRequestsEnabled(void);
extern "C" bool XeneonEarlyInitHasPinnedTopology(IORegistryEntry* device);
extern "C" void XeneonEarlyInitRecordQualifiedString(void);


