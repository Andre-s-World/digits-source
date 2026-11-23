#pragma once

#ifdef XENEON_SDK27_COMPILE_ONLY_PM_TYPES
#include "sdk27-pm-types-compile-only.h"
#endif
#include <IOKit/IOService.h>
#include <libkern/c++/OSDictionary.h>
#include <libkern/c++/OSNumber.h>
#include <libkern/c++/OSString.h>

// A passive metadata publisher. The installer supplies this personality's
// optional configuration before rebuilding the kernel collection. This class
// never reads a file, opens USB, changes enumeration or forwards touch reports.
class DigitsDisplayBindingPublisher : public IOService {
    OSDeclareDefaultStructors(DigitsDisplayBindingPublisher)

public:
    bool init(OSDictionary* properties = nullptr) override;
    bool start(IOService* provider) override;
    void stop(IOService* provider) override;
    void free() override;

private:
    static constexpr uint64_t targetVendorID = 0x27c0;
    static constexpr uint64_t targetProductID = 0x0859;
    static constexpr uint64_t targetRevision = 0x0150;
    static constexpr uint64_t targetLocationID = 0x00140000;

    OSDictionary* binding_;
    IONotifier* deviceObserver_;

    bool validateBinding(OSDictionary* binding) const;
    bool observePhysicalDevices();
    bool publishToPhysicalDevice(IOService* device);
    static bool devicePublished(
        void* target, void* reference, IOService* service, IONotifier* notifier);
};
