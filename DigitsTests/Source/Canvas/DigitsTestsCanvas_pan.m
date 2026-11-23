#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Pan)
- (void)pan:(NSPanGestureRecognizer *)recognizer
{
    if (recognizer.state == NSGestureRecognizerStateBegan ||
        recognizer.state == NSGestureRecognizerStateChanged) {
        [self markContactSessionConsumed:YES];
    }
    NSPoint translation = [recognizer translationInView:self];
    if (recognizer.state == NSGestureRecognizerStateBegan) {
        self.panBase = self.cardShift;
        self.panStartX = translation.x;
        self.panStartY = translation.y;
    }
    CGFloat width = self.bounds.size.width - [self sidebarWidth];
    self.cardShift = NSMakePoint(MAX(-width * .40, MIN(width * .40,
        self.panBase.x + translation.x - self.panStartX)),
        MAX(-self.bounds.size.height * .30, MIN(self.bounds.size.height * .30,
        self.panBase.y + translation.y - self.panStartY)));
    if (recognizer.minimumNumberOfTouches == 1) { self.dragUpdates++; self.lastAction = @"Single-finger drag"; }
    else { self.panUpdates++; self.lastAction = @"Moving together"; }
    [self setNeedsDisplay:YES];
}
@end
