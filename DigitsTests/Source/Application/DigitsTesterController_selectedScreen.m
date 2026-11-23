#import "DigitsTests.h"
@implementation DigitsTesterController (ScreenSelection)
- (NSScreen *)selectedScreen
{
    NSString *uuid = self.requestedDisplayUUID;
    if (!uuid.length) {
        NSURL *path = [NSURL fileURLWithPath:@"/Library/Application Support/Digits/DigitsDisplayBinding.plist"];
        NSDictionary *binding = [NSDictionary dictionaryWithContentsOfURL:path error:NULL];
        uuid = [binding[@"DisplayUUID"] isKindOfClass:NSString.class] ? binding[@"DisplayUUID"] : nil;
    }
    for (NSScreen *screen in NSScreen.screens) {
        if (uuid.length && [DigitsTestsDisplayUUID(screen) caseInsensitiveCompare:uuid] == NSOrderedSame) return screen;
    }
    // Never redirect a touchscreen demonstration to an unrelated display.
    // The caller verifies the binding too; this check also covers disconnection.
    return nil;
}
@end
