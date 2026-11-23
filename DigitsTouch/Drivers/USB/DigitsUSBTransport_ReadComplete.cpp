#include "DigitsUSBTransportState.hpp"
void DigitsUSBTransport::ReadComplete_Impl(OSAction *action, IOReturn status,
    uint32_t actualByteCount, uint64_t completionTimestamp) {
    (void)action;
    (void)completionTimestamp;
    ivars->readPending = false;
    if (ivars->stopping) return;
    ivars->lastUSBResult = status;
    if (status != kIOReturnSuccess) {
        // Do not reset or retry a disconnected/stalled provider. Release all virtual contacts.
        UnbindDisplay();
        PublishIdentity("Input stopped");
        return;
    }
    ++ivars->completedTransfers;
    uint8_t normalized[DigitsTouch::kReportBytes];
    const uint8_t *report = reinterpret_cast<const uint8_t *>(ivars->interruptRange.address);
    if (actualByteCount > DigitsUSB::InterruptCapacity ||
        !DigitsTouch::NormalizePhysicalReport(report, actualByteCount, normalized)) {
        ++ivars->rejectedReports;
    } else {
        ++ivars->validPhysicalReports;
        bool physicalContactIsActive = false;
        for (size_t index = 0; index < DigitsTouch::kContactSlots; ++index)
            physicalContactIsActive |= (normalized[1 + index * 5] & 1) != 0;
        // Boot publication may finish after Start. Retry on the first valid input
        // and on new contact sequences only; movement frames never query metadata.
        if (!ivars->displayBound && !ivars->publishedBindingRejected &&
            (ivars->validPhysicalReports == 1 ||
             (physicalContactIsActive && !ivars->physicalContactWasActive)))
            RestorePublishedDisplayBinding();
        ivars->physicalContactWasActive = physicalContactIsActive;
        ivars->lastHIDResult = ForwardDigitizerReport(report, actualByteCount);
        if (ivars->lastHIDResult == kIOReturnSuccess && ++ivars->forwardedReports == 1) {
            PublishTouchState("Native HID accepted first input", kIOReturnSuccess);
            PublishIdentity("Native touch active");
        }
    }
    ivars->lastUSBResult = QueueDigitizerRead();
    if (ivars->lastUSBResult != kIOReturnSuccess) {
        UnbindDisplay();
        PublishIdentity("Input stopped");
    }
}
