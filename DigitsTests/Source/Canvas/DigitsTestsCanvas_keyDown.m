#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Keyboard)
- (void)keyDown:(NSEvent *)event
{
    if (event.keyCode == 53) {
        if (self.window.styleMask & NSWindowStyleMaskFullScreen) [self.window toggleFullScreen:nil];
        else [self.window close];
        return;
    }
    [super keyDown:event];
}
@end
