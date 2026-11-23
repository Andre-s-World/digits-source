#import "DigitsTests.h"
@implementation DigitsTesterController (ResetCanvas)
- (void)reset:(id)sender
{
    (void)sender;
    [self.canvas resetCanvas];
    [self.window makeFirstResponder:self.canvas];
}
@end
