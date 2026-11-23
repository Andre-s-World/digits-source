#ifndef DIGITS_TOUCH_PROTOCOL_H
#define DIGITS_TOUCH_PROTOCOL_H
#include <stdint.h>

// Metadata only. There is deliberately no selector for supplying touch reports.
enum { kDigitsTouchProtocolVersion = 1, kDigitsTouchUserClientType = 0 };
enum { kDigitsTouchBindDisplay = 0, kDigitsTouchUnbindDisplay = 1,
       kDigitsTouchCopyStatus = 2 };
enum { kDigitsTouchProviderValidated = 1U << 0, kDigitsTouchDescriptorValidated = 1U << 1,
       kDigitsTouchDisplayBound = 1U << 2, kDigitsTouchChildCreated = 1U << 3,
       kDigitsTouchStopping = 1U << 4 };

typedef struct DigitsTouchDisplayBinding {
    uint32_t version;
    uint32_t displayID;
    uint64_t physicalUSBRegistryID;
    char displayUUID[37];
    uint8_t reserved[3];
} DigitsTouchDisplayBinding;

typedef struct DigitsTouchStatus {
    uint32_t version;
    uint32_t flags;
    uint64_t physicalUSBRegistryID;
    uint64_t interfaceRegistryID;
    uint32_t usbLocationID;
    uint32_t displayID;
    uint64_t completedTransfers;
    uint64_t validPhysicalReports;
    uint64_t forwardedReports;
    uint64_t rejectedReports;
    int32_t lastUSBResult;
    int32_t lastHIDResult;
    char displayUUID[37];
    uint8_t reserved[3];
} DigitsTouchStatus;

#ifdef __cplusplus
static_assert(sizeof(DigitsTouchDisplayBinding) == 56, "binding ABI");
static_assert(sizeof(DigitsTouchStatus) == 112, "status ABI");
#endif
#endif
