#import "DigitsTests.h"
@implementation DigitsTesterController (ToggleCounters)
- (void)toggleCounters:(DigitsTestsSwitch *)sender
{
    self.canvas.showCounters = sender.state == NSControlStateValueOn;
    [self.canvas setNeedsDisplay:YES];
    [self layoutToolbar];
}
@end
