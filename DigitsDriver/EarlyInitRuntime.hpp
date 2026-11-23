#pragma once
#include "sdk27-pm-types-compile-only.h"
#include "CreationContext.hpp"
#include "PinnedControllerShadow.hpp"
#include "PinnedControllerTable.generated.hpp"
#include "XeneonStringDevice.hpp"
#include <IOKit/IOLib.h>
#include <IOKit/IOLocks.h>
#include <IOKit/IOUserClient.h>
#include <IOKit/IONotifier.h>
#include <libkern/OSKextLib.h>
#include <libkern/c++/OSNumber.h>
#include <libkern/c++/OSString.h>
#include <mach/kmod.h>
#include <mach/mach_time.h>
#include <ptrauth.h>


namespace DigitsEarlyInit {
constexpr uint32_t kTargetRoute = 0x00140000;
constexpr const char* kAcknowledgement = "XENEON-27C0-0859-EXPERIMENT";
using OuterFunction = IOUSBHostDevice* (*)(IOService*, uint32_t, uint32_t, uint32_t);
using InnerFunction = IOUSBHostDevice* (*)(IOService*, uint32_t, uint16_t, uint32_t);

struct EarlyInitRuntime {
    IOLock* controlLock;
    IOSimpleLock* contextLock;
    IOService* controller;
    IOWorkLoop* workLoop;
    XeneonPinnedController::PreparedShadow shadow;
    OuterFunction originalOuterFactory;
    InnerFunction originalInnerFactory;
    OSKextLoadTag loadTag;
    uint32_t accepting;
    bool pinned;
    bool everPublished;
    bool hookInstalled;
    const char* state;
    uint64_t targetCreations;
    uint64_t selectedDevices;
    uint64_t allocationFailures;
    IONotifier* startupObserver;
    uint64_t automaticArmAttempts;
    uint64_t startupControllerCount;
    uint64_t startupTargetPresentCount;
    IOReturn automaticArmResult;
    uint64_t moduleStartTicks;
    uint64_t automaticArmTicks;
    uint64_t hookPublicationTicks;
    uint64_t firstTargetFactoryTicks;
    uint64_t firstQualifiedStringTicks;
    uint64_t qualifiedStringRequests;
};

extern EarlyInitRuntime driverRuntime;
extern XeneonCreationContexts creationContexts;
bool requestsEnabled();
bool registryNumberMatches(IORegistryEntry*, const char*, uint64_t);
bool registryClassMatches(IORegistryEntry*, const char*);
IOService* findTargetController();
IOService* findStartupController();
IOReturn observeControllerPublication(IOService* control);
bool controllerPublished(void*, void*, IOService*, IONotifier*);
IOReturn publishAction(OSObject*, void*, void*, void*, void*);
IOReturn disableAction(OSObject*, void*, void*, void*, void*);
void discardBeforePublication();
IOReturn arm();
IOReturn armController(IOService* controller);
IOReturn disarm();
}

extern "C" bool XeneonEarlyInitRequestsEnabled(void);
extern "C" bool XeneonEarlyInitHasPinnedTopology(IORegistryEntry* device);
extern "C" void XeneonEarlyInitRecordQualifiedString(void);
extern "C" IOUSBHostDevice* XeneonFactoryOuter(IOService*, uint32_t, uint32_t, uint32_t);
extern "C" IOUSBHostDevice* XeneonFactoryInner(IOService*, uint32_t, uint16_t, uint32_t);

class XeneonEarlyInitControl : public IOService {
    OSDeclareDefaultStructors(XeneonEarlyInitControl)
public:
    IOService* probe(IOService* provider, SInt32* score) override;
    IOReturn setProperties(OSObject* properties) override;
    void publishStatus();
};
