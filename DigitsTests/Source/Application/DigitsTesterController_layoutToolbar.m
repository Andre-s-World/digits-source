#import "DigitsTests.h"
@implementation DigitsTesterController (ToolbarLayout)
- (void)layoutToolbar
{
    if (!self.toolbarGlass || !self.canvas) return;
    NSRect canvasBounds = self.canvas.bounds;
    CGFloat playWidth = canvasBounds.size.width - self.canvas.sidebarWidth;
    NSSize fitting = self.toolbarControls.fittingSize;
    CGFloat width = MIN(ceil(fitting.width) + 28, MAX(0, playWidth - 32));
    CGFloat height = 60;
    self.toolbarGlass.frame = NSMakeRect(round((playWidth - width) / 2), 13, width, height);
    self.toolbarGlass.contentView.frame = self.toolbarGlass.bounds;
    self.toolbarControls.frame = NSMakeRect(14, 8, MAX(0, width - 28), 44);
}
@end
