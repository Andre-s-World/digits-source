#pragma once
#include "DigitsUSBTransport.h"
#include "DigitsTouchDevice.h"
#include "DigitsTouchProtocol.h"
#include "DigitsTouchReport.hpp"
#include "DigitsTouchUserClient.h"
#include <DriverKit/IOBufferMemoryDescriptor.h>
#include <DriverKit/IODispatchQueue.h>
#include <DriverKit/IOLib.h>
#include <DriverKit/OSBoolean.h>
#include <DriverKit/OSData.h>
#include <DriverKit/OSDictionary.h>
#include <DriverKit/OSNumber.h>
#include <DriverKit/OSString.h>
#include <USBDriverKit/IOUSBHostDevice.h>
#include <USBDriverKit/IOUSBHostInterface.h>
#include <USBDriverKit/USBDriverKitDefs.h>
#include <string.h>

namespace DigitsUSB {
constexpr uint16_t VendorID = 0x27c0;
constexpr uint16_t ProductID = 0x0859;
constexpr uint16_t DeviceRevision = 0x0150;
constexpr uint8_t DigitizerEndpoint = 0x81;
constexpr uint32_t InterruptCapacity = 64;
constexpr uint16_t PhysicalDescriptorBytes = 704;
}

// USB callbacks, metadata methods and Stop share the transport's serial dispatch queue.
// The small lock protects binding snapshots requested by a child's asynchronous Start.
struct DigitsUSBTransport_IVars {
    IOUSBHostInterface *interface;
    IOUSBHostDevice *device;
    IOUSBHostPipe *digitizerPipe;
    IOBufferMemoryDescriptor *interruptBuffer;
    IOAddressSegment interruptRange;
    OSAction *readCompletion;
    DigitsTouchDevice *touchDevice;
    IOLock *bindingLock;
    DigitsTouchDisplayBinding binding;
    uint64_t bindingGeneration;
    uint64_t physicalUSBRegistryID;
    uint64_t interfaceRegistryID;
    uint32_t locationID;
    bool interfaceOpen;
    bool stopping;
    bool readPending;
    bool providerValidated;
    bool descriptorValidated;
    bool displayBound;
    bool metadataClientOpen;
    // Retry missing boot metadata on a new physical contact sequence, never every frame.
    bool physicalContactWasActive;
    bool publishedBindingRejected;
    uint32_t publishedBindingAttempts;
    // A failed creation is terminal for this USB connection, never retried per input frame.
    bool touchCreationAttempted;
    kern_return_t touchCreationResult;
    uint64_t completedTransfers;
    uint64_t validPhysicalReports;
    uint64_t forwardedReports;
    uint64_t rejectedReports;
    IOReturn lastUSBResult;
    IOReturn lastHIDResult;
};
