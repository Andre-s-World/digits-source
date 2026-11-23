#import "DigitsInstallerController.h"
@implementation DigitsInstallerBackgroundView (Appearance)
- (void)viewDidChangeEffectiveAppearance {
    [super viewDidChangeEffectiveAppearance];
    self.needsDisplay = YES;
}
@end
