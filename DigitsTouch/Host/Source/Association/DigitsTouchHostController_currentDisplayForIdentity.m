#import "DigitsTouchHostController.h"
#import <ColorSync/ColorSync.h>

@implementation DigitsTouchHostController (CurrentDisplay)
- (DigitsTouchDisplayIdentity *)currentDisplayForIdentity:(DigitsTouchDisplayIdentity *)identity {
    uint32_t displayCount = 0;
    if (CGGetOnlineDisplayList(0, NULL, &displayCount) != kCGErrorSuccess || displayCount == 0)
        return nil;
    CGDirectDisplayID *displays = calloc(displayCount, sizeof(*displays));
    if (!displays)
        return nil;
    if (CGGetOnlineDisplayList(displayCount, displays, &displayCount) != kCGErrorSuccess) {
        free(displays);
        return nil;
    }
    CGDirectDisplayID matchedDisplay = kCGNullDirectDisplay;
    NSUInteger matchingCount = 0;
    for (uint32_t displayIndex = 0; displayIndex < displayCount; ++displayIndex) {
        CGDirectDisplayID display = displays[displayIndex];
        if (CGDisplayVendorNumber(display) == identity.vendorID &&
            CGDisplayModelNumber(display) == identity.productID &&
            CGDisplaySerialNumber(display) == identity.serialNumber) {
            ++matchingCount;
            matchedDisplay = display;
        }
    }
    free(displays);
    if (matchingCount != 1 || matchedDisplay == kCGNullDirectDisplay) {
        self.associationState =
            matchingCount > 1 ? @"Matching display identities are ambiguous. Touch is not bound."
                              : @"The physical display is not ready in the current desktop.";
        return nil;
    }
    if (!CGDisplayIsOnline(matchedDisplay) || !CGDisplayIsActive(matchedDisplay) ||
        CGDisplayIsAsleep(matchedDisplay) || CGDisplayIsBuiltin(matchedDisplay) ||
        CGDisplayIsInMirrorSet(matchedDisplay) || CGDisplayIsInHWMirrorSet(matchedDisplay) ||
        CGDisplayMirrorsDisplay(matchedDisplay) != kCGNullDirectDisplay) {
        self.associationState =
            @"The matching display is inactive, built in, or mirrored. Touch is not bound.";
        return nil;
    }
    CFUUIDRef uuid = CGDisplayCreateUUIDFromDisplayID(matchedDisplay);
    if (!uuid) {
        self.associationState =
            @"macOS did not provide a current display UUID. Touch is not bound.";
        return nil;
    }
    identity.displayUUID = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
    CFRelease(uuid);
    identity.displayID = matchedDisplay;
    return identity;
}
@end
