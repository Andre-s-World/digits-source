#import "DigitsTests.h"
@implementation DigitsTestsCanvas (NativeInput)
- (void)consumeNativeEvent:(NSEvent *)event
{
    if (event.type != NSEventTypeDirectTouch || event.timestamp == self.lastNativeTimestamp) return;
    self.lastNativeTimestamp = event.timestamp;
    // Shared HID observation owns contact circles once it has received a verified
    // report. AppKit still owns every gesture used to manipulate the tile.
    if (self.hidFrameCount) {
        self.nativeFrameCount++;
        return;
    }
    NSSet<NSTouch *> *touches = [event touchesMatchingPhase:NSTouchPhaseAny inView:nil];
    BOOL receivedDirectTouch = NO;
    for (NSTouch *touch in touches) {
        if (touch.type != NSTouchTypeDirect) continue;
        NSNumber *identifier = self.identityNumbers[touch.identity];
        if (!identifier) {
            identifier = @(self.nextContactIdentifier++);
            self.identityNumbers[touch.identity] = identifier;
        }
        NSPoint position = [touch locationInView:self];
        NSPoint normalized = touch.normalizedPosition;
        NSString *phase = @"hold";
        if (touch.phase & NSTouchPhaseBegan) phase = @"begin";
        else if (touch.phase & NSTouchPhaseMoved) phase = @"move";
        else if (touch.phase & NSTouchPhaseEnded) phase = @"end";
        else if (touch.phase & NSTouchPhaseCancelled) phase = @"cancel";
        BOOL ended = (touch.phase & (NSTouchPhaseEnded | NSTouchPhaseCancelled)) != 0;
        if (ended) {
            [self.activeContacts removeObjectForKey:identifier];
            [self.identityNumbers removeObjectForKey:touch.identity];
        } else {
            self.activeContacts[identifier] = @{ @"point":[NSValue valueWithPoint:position],
                @"normalized":[NSValue valueWithPoint:normalized], @"phase":phase };
        }
        NSString *row = [NSString stringWithFormat:@"C%02lu  %-6@  x %.4f  y %.4f",
            (unsigned long)identifier.unsignedIntegerValue, phase, normalized.x, normalized.y];
        [self appendStream:row identifier:identifier.unsignedIntegerValue];
        receivedDirectTouch = YES;
    }
    if (receivedDirectTouch) self.nativeFrameCount++;
    [self setNeedsDisplay:YES];
}
@end
