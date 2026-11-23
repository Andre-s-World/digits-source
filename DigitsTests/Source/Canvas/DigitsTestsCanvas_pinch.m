#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Pinch)
- (void)pinch:(NSMagnificationGestureRecognizer *)recognizer
{
    if (recognizer.state == NSGestureRecognizerStateBegan ||
        recognizer.state == NSGestureRecognizerStateChanged) {
        [self markContactSessionConsumed:NO];
    }
    if (recognizer.state == NSGestureRecognizerStateBegan) {
        self.pinchBase = self.cardScale;
        self.pinchStart = recognizer.magnification;
    }
    self.cardScale = MAX(.45, MIN(2.6,
        self.pinchBase * (1 + recognizer.magnification - self.pinchStart)));
    self.pinchUpdates++;
    self.lastAction = @"A little closer";
    [self setNeedsDisplay:YES];
}
@end
