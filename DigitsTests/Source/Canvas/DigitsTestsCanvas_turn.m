#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Turn)
- (void)turn:(NSRotationGestureRecognizer *)recognizer
{
    if (recognizer.state == NSGestureRecognizerStateBegan ||
        recognizer.state == NSGestureRecognizerStateChanged) {
        [self markContactSessionConsumed:NO];
    }
    if (recognizer.state == NSGestureRecognizerStateBegan) {
        self.turnBase = self.cardRotation;
        self.turnStart = recognizer.rotation;
    }
    // rotation is cumulative for this recognition stream; never add that total
    // every frame, which is what made the old tile spin like a fan.
    self.cardRotation = self.turnBase + recognizer.rotation - self.turnStart;
    self.rotationUpdates++;
    self.lastAction = @"Finding a new angle";
    [self setNeedsDisplay:YES];
}
@end
