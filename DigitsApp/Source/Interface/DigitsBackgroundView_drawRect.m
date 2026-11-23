#import "DigitsApplicationController.h"

@implementation DigitsBackgroundView (Drawing)
- (void)drawRect:(NSRect)dirtyRect {
    NSString *appearance = [self.effectiveAppearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
    BOOL dark = [appearance isEqualToString:NSAppearanceNameDarkAqua];
    // A calm blue field carries the same pastel touch-point palette as Tester,
    // while semantic text and native controls follow the system appearance.
    NSColor *base = dark ? [NSColor colorWithSRGBRed:0.055 green:0.077 blue:0.135 alpha:1]
                         : [NSColor colorWithSRGBRed:0.966 green:0.972 blue:0.990 alpha:1];
    [base setFill];
    NSRectFill(dirtyRect);
    NSColor *glow = dark ? [NSColor colorWithSRGBRed:0.082 green:0.115 blue:0.185 alpha:1]
                         : [NSColor colorWithSRGBRed:0.944 green:0.955 blue:0.986 alpha:1];
    [[[NSGradient alloc] initWithStartingColor:base endingColor:glow] drawInRect:self.bounds angle:-25];
    NSArray<NSColor *> *colors = @[
        NSColor.systemPurpleColor, NSColor.systemBlueColor, NSColor.systemTealColor,
        NSColor.systemOrangeColor, NSColor.systemPinkColor
    ];
    const CGFloat positions[5][3] = {
        {0.86, 0.65, 0.20}, {0.98, 0.30, 0.25}, {0.80, 0.08, 0.19},
        {0.64, 0.95, 0.15}, {0.61, 0.40, 0.11}
    };
    for (NSUInteger index = 0; index < colors.count; index++) {
        CGFloat diameter = self.bounds.size.width * positions[index][2];
        NSRect circle = NSMakeRect(self.bounds.size.width * positions[index][0] - diameter / 2,
                                   self.bounds.size.height * positions[index][1] - diameter / 2,
                                   diameter, diameter);
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:circle];
        [[colors[index] colorWithAlphaComponent:dark ? 0.085 : 0.065] setFill];
        [path fill];
        [[colors[index] colorWithAlphaComponent:0.10] setStroke];
        path.lineWidth = 1;
        [path stroke];
    }
}
@end
