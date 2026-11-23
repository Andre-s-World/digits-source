#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Appearance)
- (BOOL)isDark
{
    return [[self.effectiveAppearance bestMatchFromAppearancesWithNames:
        @[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]] isEqualToString:NSAppearanceNameDarkAqua];
}
@end
