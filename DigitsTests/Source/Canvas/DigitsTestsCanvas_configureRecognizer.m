#import "DigitsTests.h"
@implementation DigitsTestsCanvas (ConfigureRecognizer)
- (void)configureRecognizer:(NSGestureRecognizer *)recognizer
{
    recognizer.allowedTouchTypes = NSTouchTypeMaskDirect;
    recognizer.delegate = self;
    [self addGestureRecognizer:recognizer];
}
@end
