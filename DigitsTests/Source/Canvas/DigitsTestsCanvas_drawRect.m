#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Drawing)
- (void)drawRect:(NSRect)dirtyRect
{
    (void)dirtyRect;
    [self drawBackground];
    [NSGraphicsContext saveGraphicsState];
    NSRectClip(NSMakeRect(0, 0, self.bounds.size.width - [self sidebarWidth], self.bounds.size.height));
    [self drawCard];
    if (self.showTouches) [self drawContacts];
    [NSGraphicsContext restoreGraphicsState];
    [self drawSidebar];
}
@end
