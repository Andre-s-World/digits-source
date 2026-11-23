#import "DigitsTests.h"
@implementation DigitsTesterController (ToolbarAccessibility)
- (void)updateToolbarAccessibility
{
    // NSGlassEffectView owns the real material and system Reduce Transparency /
    // appearance adaptation. Only its optional interaction motion is gated here.
    self.toolbarGlass.effectIsInteractive =
        !NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    for (NSView *control in self.toolbarControls.arrangedSubviews) [control setNeedsDisplay:YES];
    [self.toolbarGlass setNeedsDisplay:YES];
}
@end
