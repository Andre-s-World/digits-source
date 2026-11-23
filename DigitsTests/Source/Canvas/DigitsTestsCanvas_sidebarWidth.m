#import "DigitsTests.h"
@implementation DigitsTestsCanvas (SidebarWidth)
- (CGFloat)sidebarWidth
{
    if (self.showStream) return MIN(430, self.bounds.size.width * .39);
    return self.showCounters ? MIN(300, self.bounds.size.width * .25) : 0;
}
@end
