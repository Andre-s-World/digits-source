#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (CloseWindow)
- (BOOL)windowShouldClose:(NSWindow *)sender {
    (void)sender;
    // Keep an in-flight administrator operation visible until its result is known.
    if (self.operationInProgress) {
        NSBeep();
        return NO;
    }
    return YES;
}
@end
