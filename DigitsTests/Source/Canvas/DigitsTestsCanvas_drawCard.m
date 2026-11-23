#import "DigitsTests.h"
@implementation DigitsTestsCanvas (CardDrawing)
- (void)drawCard
{
    NSPoint center = [self cardCenter];
    [NSGraphicsContext saveGraphicsState];
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:center.x yBy:center.y];
    [transform rotateByRadians:self.cardRotation];
    [transform scaleBy:self.cardScale];
    [transform concat];
    if (self.exploding) {
        // The same fragments travel out and then return to their exact tile grid.
        CGFloat spread = pow(sin(M_PI * self.explosionProgress), .75);
        for (NSUInteger row = 0; row < 4; row++) {
            for (NSUInteger column = 0; column < 7; column++) {
                CGFloat x = -155 + (column + .5) * (310.0 / 7);
                CGFloat y = -88 + (row + .5) * 44;
                CGFloat index = row * 7 + column;
                [NSGraphicsContext saveGraphicsState];
                NSAffineTransform *fragment = [NSAffineTransform transform];
                CGFloat angle = atan2(y, x) + sin(index * 3.7) * .25;
                CGFloat distance = 80 + fmod(index * 47, 180);
                [fragment translateXBy:x + cos(angle) * distance * spread
                    yBy:y + sin(angle) * distance * spread];
                [fragment rotateByRadians:sin(index * 2.2) * 4 * spread];
                [fragment concat];
                [[DigitsTestsContactColor((NSUInteger)index) colorWithAlphaComponent:.88] setFill];
                [[NSBezierPath bezierPathWithRoundedRect:NSMakeRect(-21, -20, 42, 40)
                    xRadius:10 yRadius:10] fill];
                [NSGraphicsContext restoreGraphicsState];
            }
        }
    } else {
        NSBezierPath *card = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(-155, -88, 310, 176)
            xRadius:31 yRadius:31];
        NSShadow *shadow = [NSShadow new];
        shadow.shadowColor = DigitsTestsColor(0x1C2245, [self isDark] ? .4 : .16);
        shadow.shadowBlurRadius = 32;
        shadow.shadowOffset = NSMakeSize(0, -12);
        [shadow set];
        [DigitsTestsColor(0x8876EC, 1) setFill]; [card fill];
        [[NSShadow new] set];
        NSArray *starts = @[@0x8E79F0, @0x6B9EE2, @0xC780C5, @0x65B8B1];
        NSArray *ends = @[@0x4CADD0, @0x7F80E4, @0xE4A189, @0x80BDD7];
        NSUInteger theme = self.tapCount % starts.count;
        NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:DigitsTestsColor([starts[theme] unsignedIntValue], 1)
            endingColor:DigitsTestsColor([ends[theme] unsignedIntValue], 1)];
        [gradient drawInBezierPath:card angle:-25];
        for (NSUInteger i = 0; i < 5; i++) {
            [DigitsTestsContactColor(i) setFill];
            [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(-49.0 + (CGFloat)i * 22.0, 38, 11, 11)] fill];
        }
        DigitsTestsDrawText(@"Make a move", NSMakeRect(-124, -13, 266, 43), 34,
            NSColor.whiteColor, NSFontWeightThin);
        DigitsTestsDrawText(@"A little tap goes a long way", NSMakeRect(-111, -44, 240, 24), 15,
            [NSColor.whiteColor colorWithAlphaComponent:.84], NSFontWeightLight);
        if (self.bounceEnergy > .01) {
            NSRect energy = NSMakeRect(-100, -65, 200 * MIN(1, self.bounceEnergy), 3);
            [[NSColor.whiteColor colorWithAlphaComponent:.65] setFill];
            [[NSBezierPath bezierPathWithRoundedRect:energy xRadius:1.5 yRadius:1.5] fill];
        }
    }
    [NSGraphicsContext restoreGraphicsState];
}
@end
