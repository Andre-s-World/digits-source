#import "DigitsInstallerController.h"
@implementation DigitsInstallerBackgroundView (Drawing)
- (void)drawRect:(NSRect)dirtyRect {
    BOOL dark = [[self.effectiveAppearance bestMatchFromAppearancesWithNames:
        @[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]] isEqualToString:NSAppearanceNameDarkAqua];
    NSColor *base = dark ? [NSColor colorWithSRGBRed:0.055 green:0.077 blue:0.135 alpha:1]
                         : [NSColor colorWithSRGBRed:0.966 green:0.972 blue:0.990 alpha:1];
    NSColor *glow = dark ? [NSColor colorWithSRGBRed:0.082 green:0.115 blue:0.185 alpha:1]
                         : [NSColor colorWithSRGBRed:0.944 green:0.955 blue:0.986 alpha:1];
    [base setFill];
    NSRectFill(dirtyRect);
    [[[NSGradient alloc] initWithStartingColor:base endingColor:glow] drawInRect:self.bounds angle:-25];
    NSArray<NSColor *> *colors = @[NSColor.systemPurpleColor, NSColor.systemBlueColor,
        NSColor.systemTealColor, NSColor.systemOrangeColor, NSColor.systemPinkColor];
    const CGFloat circles[5][3] = {{0.92,0.85,0.24},{0.76,0.62,0.18},{0.98,0.32,0.22},
                                  {0.70,0.08,0.16},{0.55,0.93,0.12}};
    for (NSUInteger index = 0; index < colors.count; index++) {
        CGFloat diameter = NSWidth(self.bounds) * circles[index][2];
        NSRect circle = NSMakeRect(NSWidth(self.bounds)*circles[index][0]-diameter/2,
            NSHeight(self.bounds)*circles[index][1]-diameter/2, diameter, diameter);
        NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:circle];
        [[colors[index] colorWithAlphaComponent:dark ? 0.09 : 0.07] setFill];
        [path fill];
        [[colors[index] colorWithAlphaComponent:0.12] setStroke];
        [path stroke];
    }
}
@end
