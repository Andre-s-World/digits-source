#import "DigitsTests.h"
@implementation DigitsTesterController (ToggleTouches)
- (void)toggleTouches:(DigitsTestsSwitch *)sender
{
    self.canvas.showTouches = sender.state == NSControlStateValueOn;
    [self.canvas setNeedsDisplay:YES];
}
@end
