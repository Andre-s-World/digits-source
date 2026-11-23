#import "DigitsApplicationController.h"

@implementation DigitsBackgroundView (Appearance)
- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    NSString *appearance = [self.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
    NSString *resource = [appearance isEqualToString:NSAppearanceNameDarkAqua] ? @"Digits-Dark" : @"Digits-Light";
    NSImage *icon = [[NSImage alloc] initWithContentsOfURL:[NSBundle.mainBundle URLForResource:resource withExtension:@"icns"]];
    if (icon) {
        NSApp.applicationIconImage = icon;
        for (NSView *view in self.subviews) {
            if ([view isKindOfClass:NSImageView.class])
                ((NSImageView *)view).image = icon;
        }
    }
    self.needsDisplay = YES;
}
@end
