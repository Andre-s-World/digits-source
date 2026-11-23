#import "DigitsTests.h"
@implementation DigitsTestsCanvas (SimultaneousGestures)
- (BOOL)gestureRecognizer:(NSGestureRecognizer *)recognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(NSGestureRecognizer *)other
{
    (void)recognizer;
    (void)other;
    return YES;
}
@end
