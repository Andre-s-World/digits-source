#import "DigitsTests.h"
@implementation DigitsTestsSwitch (IntrinsicSize)
- (NSSize)intrinsicContentSize
{
    NSSize labelSize = [self.title sizeWithAttributes:@{NSFontAttributeName:self.font}];
    return NSMakeSize(ceil(labelSize.width) + 55, 44);
}
@end
