#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Background)
- (void)drawBackground
{
    BOOL dark = [self isDark];
    CGFloat width = self.bounds.size.width - [self sidebarWidth], height = self.bounds.size.height;
    NSGradient *background = [[NSGradient alloc] initWithStartingColor:DigitsTestsColor(dark ? 0x10172D : 0xF7F5FC, 1)
        endingColor:DigitsTestsColor(dark ? 0x142D3A : 0xEAF5F8, 1)];
    [background drawInRect:self.bounds angle:-25];
    [NSGraphicsContext saveGraphicsState];
    NSRectClip(NSMakeRect(0, 0, width, height));
    NSArray *colors = @[DigitsTestsColor(0xA98CF2, .14), DigitsTestsColor(0x69D3CD, .12),
        DigitsTestsColor(0xE5AD8E, .08)];
    NSArray *rects = @[[NSValue valueWithRect:NSMakeRect(-140, height - 470, 650, 600)],
        [NSValue valueWithRect:NSMakeRect(width - 480, -250, 740, 650)],
        [NSValue valueWithRect:NSMakeRect(width * .45, height - 310, 460, 440)]];
    for (NSUInteger i = 0; i < colors.count; i++) {
        NSGradient *wash = [[NSGradient alloc] initWithStartingColor:colors[i]
            endingColor:[colors[i] colorWithAlphaComponent:0]];
        [wash drawInBezierPath:[NSBezierPath bezierPathWithOvalInRect:[rects[i] rectValue]]
            relativeCenterPosition:NSZeroPoint];
    }
    [NSGraphicsContext restoreGraphicsState];
    NSColor *ink = DigitsTestsColor(dark ? 0xF7F5FF : 0x28314B, 1);
    NSColor *muted = DigitsTestsColor(dark ? 0xB1BBD3 : 0x6C7691, 1);
    DigitsTestsDrawText(@"Digits Tester", NSMakeRect(30, height - 61, width - 60, 41), 32, ink, NSFontWeightThin);
    DigitsTestsDrawText(@"Drag the tile. Pinch. Turn. Tap until it surprises you.",
        NSMakeRect(30, 86, width - 60, 27), 17, muted, NSFontWeightLight);
}
@end
