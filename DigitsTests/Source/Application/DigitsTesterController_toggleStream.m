#import "DigitsTests.h"
@implementation DigitsTesterController (ToggleStream)
- (void)toggleStream:(DigitsTestsSwitch *)sender
{
    self.canvas.showStream = sender.state == NSControlStateValueOn;
    [self.canvas setNeedsDisplay:YES];
    [self layoutToolbar];
}
@end
