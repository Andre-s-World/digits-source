#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Bounce)
- (void)bounceCard
{
    if (self.exploding) return;
    self.bounceEnergy = MIN(1.2, self.bounceEnergy + .19);
    self.bounceVelocity += 250 + self.bounceEnergy * 340;
    self.lastAction = self.bounceEnergy >= 1 ? @"A little too much enthusiasm" : @"Keep tapping…";
    if (self.bounceEnergy >= 1) {
        self.exploding = YES;
        self.explosionProgress = 0;
    }
    if (!self.animationTimer) {
        self.lastAnimationTime = CACurrentMediaTime();
        __weak DigitsTestsCanvas *weakSelf = self;
        self.animationTimer = [NSTimer timerWithTimeInterval:1.0 / 60.0 repeats:YES block:^(NSTimer *timer) {
            [weakSelf animateFrame:timer];
        }];
        [[NSRunLoop mainRunLoop] addTimer:self.animationTimer forMode:NSRunLoopCommonModes];
    }
    [self setNeedsDisplay:YES];
}
@end
