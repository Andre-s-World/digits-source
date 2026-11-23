#import "DigitsInstallerActivationSession.h"

@implementation DigitsInstallerActivationSession (Completion)
- (void)finishWithEvent:(NSDictionary *)event status:(int)status {
    if (self.finished)
        return;
    self.finished = YES;
    self.exitStatus = status;
    [self emitEvent:event];
    [NSApp stop:nil];
    // Wake the application loop so the synchronous installer child can exit.
    [NSApp postEvent:[NSEvent otherEventWithType:NSEventTypeApplicationDefined
        location:NSZeroPoint modifierFlags:0 timestamp:0 windowNumber:0
        context:nil subtype:0 data1:0 data2:0] atStart:NO];
}
@end
