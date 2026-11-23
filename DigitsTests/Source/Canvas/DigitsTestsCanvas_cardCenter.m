#import "DigitsTests.h"
@implementation DigitsTestsCanvas (CardCenter)
- (NSPoint)cardCenter
{
    CGFloat width = self.bounds.size.width - [self sidebarWidth];
    return NSMakePoint(width * .5 + self.cardShift.x,
        self.bounds.size.height * .46 + self.cardShift.y + self.bouncePosition);
}
@end
