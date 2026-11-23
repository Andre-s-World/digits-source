#include "DigitsTouchReport.hpp"
#include <string.h>
bool DigitsTouch::NormalizePhysicalReport(const uint8_t *physicalReport, size_t reportLength,
    uint8_t *normalizedReport) {
    if (!physicalReport || !normalizedReport || reportLength != kReportBytes ||
        physicalReport[0] != 0x0d || physicalReport[53] > kContactSlots) return false;
    uint8_t normalized[kReportBytes];
    memcpy(normalized, physicalReport, sizeof(normalized));
    uint16_t activeIdentifiers = 0;
    size_t activeCount = 0;
    for (size_t index = 0; index < kContactSlots; ++index) {
        const size_t offset = 1 + index * 5;
        const uint8_t flags = normalized[offset];
        if ((flags & 0x0e) != 0) return false;
        const uint8_t identifier = flags >> 4;
        // Contact IDs are the descriptor's four-bit 0..15 field; active IDs must be unique.
        if (flags & 1) {
            const uint16_t identifierBit = static_cast<uint16_t>(1U << identifier);
            if (activeIdentifiers & identifierBit) return false;
            activeIdentifiers |= identifierBit;
            ++activeCount;
        }
        uint16_t x = static_cast<uint16_t>(normalized[offset + 1] |
            (static_cast<uint16_t>(normalized[offset + 2]) << 8));
        uint16_t y = static_cast<uint16_t>(normalized[offset + 3] |
            (static_cast<uint16_t>(normalized[offset + 4]) << 8));
        // Measured firmware may emit exactly max+1 at an edge. No wider clamping is allowed.
        if (x == kMaximumX + 1) x = kMaximumX;
        if (y == kMaximumY + 1) y = kMaximumY;
        if (x > kMaximumX || y > kMaximumY) return false;
        normalized[offset + 1] = static_cast<uint8_t>(x);
        normalized[offset + 2] = static_cast<uint8_t>(x >> 8);
        normalized[offset + 3] = static_cast<uint8_t>(y);
        normalized[offset + 4] = static_cast<uint8_t>(y >> 8);
        normalized[offset] = static_cast<uint8_t>((flags & 0xfd) | ((flags & 1) << 1));
    }
    // A release may advertise one changed contact with no currently active tips.
    if (activeCount > physicalReport[53]) return false;
    memcpy(normalizedReport, normalized, sizeof(normalized));
    return true;
}
