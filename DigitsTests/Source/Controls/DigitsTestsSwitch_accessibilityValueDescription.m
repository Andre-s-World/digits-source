#import "DigitsTests.h"
@implementation DigitsTestsSwitch (AccessibleValue)
- (NSString *)accessibilityValueDescription
{
    return self.state == NSControlStateValueOn ? @"On" : @"Off";
}
@end
