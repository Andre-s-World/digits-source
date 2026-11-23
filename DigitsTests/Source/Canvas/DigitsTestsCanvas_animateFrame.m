#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Animation)
- (void)animateFrame:(NSTimer *)timer
{
    NSTimeInterval now = CACurrentMediaTime();
    CGFloat delta = MIN(.04, MAX(.001, now - self.lastAnimationTime));
    self.lastAnimationTime = now;
    if (self.exploding) {
        self.explosionProgress += delta / 1.8;
        self.bouncePosition *= .85;
        self.bounceVelocity = 0;
        if (self.explosionProgress >= 1) {
            self.exploding = NO;
            self.explosionProgress = 0;
            self.bounceEnergy = 0;
            self.lastAction = @"Together again";
        }
    } else {
        CGFloat acceleration = -65 * self.bouncePosition - 5.5 * self.bounceVelocity;
        self.bounceVelocity += acceleration * delta;
        self.bouncePosition += self.bounceVelocity * delta;
        self.bounceEnergy = MAX(0, self.bounceEnergy - delta * .045);
    }
    if (!self.exploding && fabs(self.bouncePosition) < .2 && fabs(self.bounceVelocity) < .5) {
        self.bouncePosition = 0;
        [timer invalidate];
        self.animationTimer = nil;
    }
    [self setNeedsDisplay:YES];
}
@end
