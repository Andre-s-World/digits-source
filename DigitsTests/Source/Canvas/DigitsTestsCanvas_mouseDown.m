#import "DigitsTests.h"
@implementation DigitsTestsCanvas (MousePreview)
- (void)mouseDown:(NSEvent *)event
{
    [self.window makeFirstResponder:self];
    // A mouse click previews animation only; finger tap counters belong to HID sessions.
    if ([self containsCardPoint:[self convertPoint:event.locationInWindow fromView:nil]]) [self bounceCard];
}
@end
