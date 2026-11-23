#import "DigitsTests.h"
@implementation DigitsTesterController (WindowClose)
- (void)windowWillClose:(NSNotification *)notification
{
    (void)notification;
    if (self.eventMonitor) [NSEvent removeMonitor:self.eventMonitor];
    self.eventMonitor = nil;
    if (self.accessibilityObserver)
        [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self.accessibilityObserver];
    self.accessibilityObserver = nil;
    self.toolbarGlass = nil;
    self.toolbarControls = nil;
    [self.reportObserver stop];
    self.reportObserver = nil;
    [self.canvas.animationTimer invalidate];
    self.canvas.animationTimer = nil;
    self.window = nil;
    self.canvas = nil;
}
@end
