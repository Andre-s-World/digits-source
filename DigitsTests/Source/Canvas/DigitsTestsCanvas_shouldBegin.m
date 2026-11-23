#import "DigitsTests.h"
@implementation DigitsTestsCanvas (GestureBegin)
- (BOOL)gestureRecognizerShouldBegin:(NSGestureRecognizer *)recognizer
{
    return !self.exploding && [self containsCardPoint:[recognizer locationInView:self]];
}
@end
