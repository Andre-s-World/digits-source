#import "DigitsTests.h"
NSString *DigitsTestsDisplayUUID(NSScreen *screen)
{
    NSNumber *identifier = screen.deviceDescription[@"NSScreenNumber"];
    CFUUIDRef uuid = identifier ? CGDisplayCreateUUIDFromDisplayID(identifier.unsignedIntValue) : NULL;
    if (!uuid) return @"";
    NSString *result = CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuid));
    CFRelease(uuid);
    return result ?: @"";
}
