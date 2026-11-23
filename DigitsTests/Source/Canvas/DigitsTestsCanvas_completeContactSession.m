#import "DigitsTests.h"
@implementation DigitsTestsCanvas (CompleteContactSession)
- (void)completeContactSession:(DigitsTestsTouchSession *)session
{
    if (session.classified) return;
    session.classified = YES;
    NSUInteger count = session.maximumCount;
    if (session.cardDragRecognized && count == 1) self.oneFingerDragCount++;
    if (session.cardDragRecognized && count == 2) self.twoFingerDragCount++;
    NSTimeInterval duration = session.endedAt - session.startedAt;
    BOOL simultaneousCohort = !session.cohortChanged && session.origins.count == count;
    BOOL tap = !session.consumed && simultaneousCohort && count >= 1 && count <= 10 &&
        duration <= 1.1 && session.lastContactAddedAt - session.startedAt <= .65 &&
        session.maximumTravel <= 14;
    if (tap) {
        self.tapCounts[count - 1] = @([self.tapCounts[count - 1] unsignedIntegerValue] + 1);
        self.tapCount++;
        self.lastAction = [NSString stringWithFormat:@"%lu-finger tap", (unsigned long)count];
        if (session.allContactsBeganOnCard) [self bounceCard];
    }
    BOOL swipe = !session.consumed && !session.anyContactBeganOnCard && simultaneousCohort &&
        count >= 1 && count <= 5 && duration >= .08 && duration <= 1.5 &&
        session.lastContactAddedAt - session.startedAt <= .30;
    NSPoint averageDelta = NSZeroPoint;
    for (NSNumber *identifier in session.origins) {
        NSPoint origin = session.origins[identifier].pointValue;
        NSPoint last = session.latest[identifier].pointValue;
        averageDelta.x += last.x - origin.x;
        averageDelta.y += last.y - origin.y;
    }
    if (count) { averageDelta.x /= count; averageDelta.y /= count; }
    CGFloat centroidDistance = hypot(averageDelta.x, averageDelta.y);
    swipe &= centroidDistance >= 80;
    for (NSNumber *identifier in session.origins) {
        NSPoint origin = session.origins[identifier].pointValue;
        NSPoint last = session.latest[identifier].pointValue;
        CGFloat dx = last.x - origin.x, dy = last.y - origin.y;
        CGFloat distance = hypot(dx, dy);
        CGFloat direction = distance > 0 && centroidDistance > 0 ?
            (dx * averageDelta.x + dy * averageDelta.y) / (distance * centroidDistance) : 0;
        swipe &= distance >= 60 && direction >= .8 &&
            [session.pathLengths[identifier] doubleValue] <= distance * 1.6;
    }
    if (swipe) {
        self.swipeCounts[count - 1] = @([self.swipeCounts[count - 1] unsignedIntegerValue] + 1);
        self.lastAction = [NSString stringWithFormat:@"%lu-finger swipe", (unsigned long)count];
    }
    [self setNeedsDisplay:YES];
}
@end
