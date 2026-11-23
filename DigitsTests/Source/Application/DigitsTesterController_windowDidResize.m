#import "DigitsTests.h"
@implementation DigitsTesterController (WindowResize)
- (void)windowDidResize:(NSNotification *)notification
{
    (void)notification;
    [self layoutToolbar];
}
@end
