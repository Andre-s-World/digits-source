#import "DigitsTests.h"
@implementation DigitsTestsSwitch (Initialization)
- (instancetype)initWithTitle:(NSString *)title accentColor:(NSColor *)accent target:(id)target action:(SEL)action
{
    self = [super initWithFrame:NSZeroRect];
    if (!self) return nil;
    [self setButtonType:NSButtonTypeSwitch];
    self.title = title;
    self.accentColor = accent;
    self.target = target;
    self.action = action;
    self.font = [NSFont systemFontOfSize:15 weight:NSFontWeightLight];
    self.bordered = NO;
    self.focusRingType = NSFocusRingTypeNone;
    self.accessibilityLabel = title;
    self.accessibilityRole = NSAccessibilityCheckBoxRole;
    self.accessibilitySubrole = NSAccessibilitySwitchSubrole;
    return self;
}
@end
