#import "DigitsInstallerController.h"
#import <CoreGraphics/CoreGraphics.h>
NSArray<DigitsInstallerDisplayOption *> *DigitsInstallerCopyDisplayOptions(void) {
    NSMutableArray<DigitsInstallerDisplayOption *> *options = [NSMutableArray array];
    for (NSScreen *screen in NSScreen.screens) {
        NSNumber *number = screen.deviceDescription[@"NSScreenNumber"];
        if (!number)
            continue;
        CGDirectDisplayID displayID = number.unsignedIntValue;
        CFUUIDRef uuid = CGDisplayCreateUUIDFromDisplayID(displayID);
        if (!uuid)
            continue;
        NSString *uuidString = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
        CFRelease(uuid);
        if (!uuidString)
            continue;
        DigitsInstallerDisplayOption *option = [DigitsInstallerDisplayOption new];
        option.name = screen.localizedName ?: @"Display";
        option.displayUUID = uuidString.uppercaseString;
        CGDisplayModeRef mode = CGDisplayCopyDisplayMode(displayID);
        // Scaled UI points are not the physical pixel dimensions of the current mode.
        NSString *pixels = mode ? [NSString stringWithFormat:@"%zu × %zu",
            CGDisplayModeGetPixelWidth(mode), CGDisplayModeGetPixelHeight(mode)] : @"Unavailable";
        option.detail = [NSString stringWithFormat:@"%@ pixels  ·  %.0f × %.0f pt UI\n%@ display",
            pixels, NSWidth(screen.frame), NSHeight(screen.frame),
            CGDisplayIsBuiltin(displayID) ? @"Built-in" : @"External"];
        if (mode)
            CGDisplayModeRelease(mode);
        [options addObject:option];
    }
    return options;
}
