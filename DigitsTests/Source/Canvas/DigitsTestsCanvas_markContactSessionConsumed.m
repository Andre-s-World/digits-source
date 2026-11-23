#import "DigitsTests.h"
@implementation DigitsTestsCanvas (ConsumedContactSession)
- (void)markContactSessionConsumed:(BOOL)cardDrag
{
    DigitsTestsTouchSession *session = self.touchSession ?: self.pendingTouchSession;
    session.consumed = YES;
    session.cardDragRecognized |= cardDrag;
}
@end
