#import "DigitsTests.h"
@implementation DigitsTestsCanvas (AppearanceChange)
- (void)viewDidChangeEffectiveAppearance
{
    [super viewDidChangeEffectiveAppearance];
    [self setNeedsDisplay:YES];
}
@end
