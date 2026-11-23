#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Tap)
- (void)tap:(NSClickGestureRecognizer *)recognizer
{
    // Retained as an internal action boundary; verified HID sessions own taps.
    (void)recognizer;
}
@end
