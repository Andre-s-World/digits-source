#import "DigitsTests.h"
@implementation DigitsTestsCanvas (ContactSessions)
- (void)observeContactSession:(NSDictionary<NSNumber *, NSDictionary *> *)contacts scanTime:(uint16_t)scanTime
{
    NSTimeInterval now = CACurrentMediaTime();
    DigitsTestsTouchSession *session = self.touchSession;
    if (!session && contacts.count) {
        session = [DigitsTestsTouchSession new];
        session.startedAt = now;
        session.firstScanTime = scanTime;
        session.allContactsBeganOnCard = YES;
        session.origins = [NSMutableDictionary dictionary];
        session.latest = [NSMutableDictionary dictionary];
        session.pathLengths = [NSMutableDictionary dictionary];
        session.previousIdentifiers = [NSSet set];
        self.touchSession = session;
    }
    if (!session) return;
    session.lastScanTime = scanTime;
    session.maximumCount = MAX(session.maximumCount, contacts.count);
    for (NSNumber *identifier in contacts) {
        NSPoint position = [contacts[identifier][@"point"] pointValue];
        NSValue *originValue = session.origins[identifier];
        if (!originValue) {
            session.origins[identifier] = [NSValue valueWithPoint:position];
            session.pathLengths[identifier] = @0;
            session.lastContactAddedAt = now;
            BOOL onCard = [self containsCardPoint:position];
            session.allContactsBeganOnCard &= onCard;
            session.anyContactBeganOnCard |= onCard;
            originValue = session.origins[identifier];
        } else if (![session.previousIdentifiers containsObject:identifier]) {
            // Reuse before all-up is a changed cohort, not a simultaneous tap/swipe.
            session.cohortChanged = YES;
        }
        NSPoint origin = originValue.pointValue;
        NSPoint previous = session.latest[identifier] ? session.latest[identifier].pointValue : position;
        CGFloat distance = hypot(position.x - previous.x, position.y - previous.y);
        session.pathLengths[identifier] = @([session.pathLengths[identifier] doubleValue] + distance);
        session.maximumTravel = MAX(session.maximumTravel,
            hypot(position.x - origin.x, position.y - origin.y));
        session.latest[identifier] = [NSValue valueWithPoint:position];
    }
    session.previousIdentifiers = [NSSet setWithArray:contacts.allKeys];
    if (contacts.count) return;
    session.endedAt = now;
    self.touchSession = nil;
    self.pendingTouchSession = session;
    NSUInteger generation = self.sessionGeneration;
    __weak DigitsTestsCanvas *weakSelf = self;
    // WindowServer recognition and shared HID callbacks may arrive in either order.
    // Brief deferral lets the native recognizer consume its just-finished session.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 80 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        DigitsTestsCanvas *canvas = weakSelf;
        if (!canvas || canvas.sessionGeneration != generation) return;
        [canvas completeContactSession:session];
        if (canvas.pendingTouchSession == session) canvas.pendingTouchSession = nil;
    });
}
@end
