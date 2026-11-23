#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Reset)
- (void)resetCanvas
{
    [self.animationTimer invalidate];
    self.animationTimer = nil;
    self.dragUpdates = self.panUpdates = self.pinchUpdates = self.rotationUpdates = self.tapCount = 0;
    self.oneFingerDragCount = self.twoFingerDragCount = 0;
    for (NSUInteger i = 0; i < self.tapCounts.count; i++) self.tapCounts[i] = @0;
    for (NSUInteger i = 0; i < self.swipeCounts.count; i++) self.swipeCounts[i] = @0;
    self.touchSession = self.pendingTouchSession = nil;
    self.sessionGeneration++;
    self.cardScale = 1;
    self.cardRotation = self.bouncePosition = self.bounceVelocity = self.bounceEnergy = 0;
    self.cardShift = NSZeroPoint;
    self.exploding = NO;
    self.lastAction = @"Make it yours";
    [self.streamRows removeAllObjects];
    [self setNeedsDisplay:YES];
}
@end
