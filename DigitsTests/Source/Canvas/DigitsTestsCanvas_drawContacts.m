#import "DigitsTests.h"
@implementation DigitsTestsCanvas (ContactDrawing)
- (void)drawContacts
{
    for (NSNumber *identifier in self.activeContacts) {
        NSPoint point = [self.activeContacts[identifier][@"point"] pointValue];
        if (!NSPointInRect(point, self.bounds)) continue;
        NSColor *color = DigitsTestsContactColor(identifier.unsignedIntegerValue);
        [[color colorWithAlphaComponent:.10] setFill];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - 40, point.y - 40, 80, 80)] fill];
        NSBezierPath *disc = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - 24, point.y - 24, 48, 48)];
        [[color colorWithAlphaComponent:.27] setFill]; [disc fill];
        [[color colorWithAlphaComponent:.75] setStroke]; disc.lineWidth = 1; [disc stroke];
        [[NSColor.whiteColor colorWithAlphaComponent:.6] setFill];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - 2, point.y - 2, 4, 4)] fill];
    }
}
@end
