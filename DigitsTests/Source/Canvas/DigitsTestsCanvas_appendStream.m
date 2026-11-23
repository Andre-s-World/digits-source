#import "DigitsTests.h"
@implementation DigitsTestsCanvas (StreamRows)
- (void)appendStream:(NSString *)text identifier:(NSUInteger)identifier
{
    [self.streamRows insertObject:@{ @"text":text, @"identifier":@(identifier) } atIndex:0];
    if (self.streamRows.count > 100) [self.streamRows removeLastObject];
}
@end
