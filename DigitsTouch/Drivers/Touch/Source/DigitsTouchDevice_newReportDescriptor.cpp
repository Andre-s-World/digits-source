#include "DigitsTouchDevice_internal.hpp"

OSData *DigitsTouchDevice::newReportDescriptor() {
    return OSData::withBytes(DigitsTouch::kReportDescriptor,
                             sizeof(DigitsTouch::kReportDescriptor));
}
