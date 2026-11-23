#ifndef DIGITS_TOUCH_DEVICE_INTERNAL_HPP
#define DIGITS_TOUCH_DEVICE_INTERNAL_HPP
#include "DigitsTouchDevice.h"
#include "DigitsTouchReport.hpp"
#include "DigitsTouchProtocol.h"
#include "DigitsUSBTransport.h"
#include <DriverKit/IOBufferMemoryDescriptor.h>
#include <DriverKit/IOLib.h>
#include <DriverKit/IOMemoryMap.h>
#include <DriverKit/OSBoolean.h>
#include <DriverKit/OSData.h>
#include <DriverKit/OSDictionary.h>
#include <DriverKit/OSNumber.h>
#include <DriverKit/OSString.h>
#include <HIDDriverKit/IOHIDDeviceKeys.h>
#include <string.h>
struct DigitsTouchDevice_IVars {
    IOLock *reportLock;
    bool ready;
    uint8_t lastReport[DigitsTouch::kReportBytes];
    IOBufferMemoryDescriptor *inputBuffer;
    IOAddressSegment inputRange;
    DigitsUSBTransport *transport;
    uint64_t bindingGeneration;
    DigitsTouchDisplayBinding binding;
};
#endif
