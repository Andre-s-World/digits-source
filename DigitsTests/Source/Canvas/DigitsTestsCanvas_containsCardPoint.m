#import "DigitsTests.h"
@implementation DigitsTestsCanvas (CardHitTest)
- (BOOL)containsCardPoint:(NSPoint)point
{
    if (self.exploding) return NO;
    NSPoint center = [self cardCenter];
    CGFloat horizontal = point.x - center.x;
    CGFloat vertical = point.y - center.y;
    CGFloat cosine = cos(self.cardRotation), sine = sin(self.cardRotation);
    // Hit testing is in the tile's own rotated/scaled space, never its bounding box.
    NSPoint local = NSMakePoint((horizontal * cosine + vertical * sine) / self.cardScale,
        (-horizontal * sine + vertical * cosine) / self.cardScale);
    NSBezierPath *card = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(-155, -88, 310, 176)
        xRadius:31 yRadius:31];
    return [card containsPoint:local];
}
@end
