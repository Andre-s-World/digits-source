#import "DigitsTests.h"
@implementation DigitsTestsCanvas (TouchTarget)
- (BOOL)gestureRecognizer:(NSGestureRecognizer *)recognizer shouldReceiveTouch:(NSTouch *)touch
{
    (void)recognizer;
    // AppKit keeps an accepted contact for the rest of its gesture, even after it
    // travels outside the tile. A new touch on the background does not move it.
    return touch.type == NSTouchTypeDirect && [self containsCardPoint:[touch locationInView:self]];
}
@end
