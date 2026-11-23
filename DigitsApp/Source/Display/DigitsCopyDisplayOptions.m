#import "DigitsApplicationController.h"
#import <CoreGraphics/CoreGraphics.h>

NSArray<DigitsDisplayOption *> *DigitsCopyDisplayOptions(void) {
    NSMutableArray<DigitsDisplayOption *> *options = [NSMutableArray array];
    for (NSScreen *screen in NSScreen.screens) {
        NSNumber *screenNumber = screen.deviceDescription[@"NSScreenNumber"];
        if (!screenNumber)
            continue;
        CGDirectDisplayID displayID = screenNumber.unsignedIntValue;
        CFUUIDRef displayUUID = CGDisplayCreateUUIDFromDisplayID(displayID);
        if (!displayUUID)
            continue;
        NSString *uuid = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, displayUUID));
        CFRelease(displayUUID);
        if (!uuid)
            continue;
        DigitsDisplayOption *option = [DigitsDisplayOption new];
        option.name = screen.localizedName ?: @"Display";
        option.displayUUID = uuid.uppercaseString;
        NSString *kind = CGDisplayIsBuiltin(displayID) ? @"Built-in" : @"External";
        CGDisplayModeRef mode = CGDisplayCopyDisplayMode(displayID);
        // Current mode pixels and AppKit layout points are different facts on
        // scaled displays. Never relabel the UI dimensions as physical pixels.
        NSString *pixels = mode ? [NSString stringWithFormat:@"%zu × %zu",
            CGDisplayModeGetPixelWidth(mode), CGDisplayModeGetPixelHeight(mode)] : @"Unavailable";
        option.detail = [NSString stringWithFormat:@"Pixel resolution: %@\nUI resolution: %.0f × %.0f pt  ·  %@",
            pixels, NSWidth(screen.frame), NSHeight(screen.frame), kind];
        if (mode)
            CGDisplayModeRelease(mode);
        [options addObject:option];
    }
    return options;
}
