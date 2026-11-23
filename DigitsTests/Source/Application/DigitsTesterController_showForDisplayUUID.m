#import "DigitsTests.h"
@implementation DigitsTesterController (Show)
- (void)showForDisplayUUID:(NSString *)uuid
{
    self.requestedDisplayUUID = uuid;
    NSScreen *screen = [self selectedScreen];
    if (!screen) {
        NSAlert *alert = [NSAlert new];
        alert.messageText = @"The bound display is unavailable.";
        alert.informativeText = @"Connect the display selected in Digits before opening the Tester.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
        return;
    }
    if (self.window) {
        if ([DigitsTestsDisplayUUID(self.window.screen) caseInsensitiveCompare:DigitsTestsDisplayUUID(screen)] != NSOrderedSame) {
            [self.window close];
        } else {
            // An explicit Tester click retries only our shared observer. A prior
            // open failure or a replaced virtual device must not require closing
            // the window; native gesture handling remains in the same canvas.
            if (!self.reportObserver) self.reportObserver = [DigitsTestsReportObserver new];
            NSError *reportError = nil;
            if (![self.reportObserver startForDisplayUUID:DigitsTestsDisplayUUID(screen)
                canvas:self.canvas error:&reportError]) {
                self.canvas.reportObserverStatus = reportError.localizedDescription ?:
                    @"Touch report observation unavailable.";
            }
            [self.canvas setNeedsDisplay:YES];
            [self.window makeKeyAndOrderFront:nil];
            [self.window makeFirstResponder:self.canvas];
            [NSApp activateIgnoringOtherApps:YES];
            return;
        }
    }
    [self buildWindow];
    self.reportObserver = [DigitsTestsReportObserver new];
    NSError *reportError = nil;
    if (![self.reportObserver startForDisplayUUID:DigitsTestsDisplayUUID(screen) canvas:self.canvas error:&reportError]) {
        self.canvas.reportObserverStatus = reportError.localizedDescription ?: @"Touch report observation unavailable.";
    }
    __weak DigitsTesterController *weakSelf = self;
    // This app-local observer cannot capture input in another application. It
    // observes native frames before our own gesture recognizers process them.
    self.eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskDirectTouch
        handler:^NSEvent *(NSEvent *event) {
            DigitsTesterController *controller = weakSelf;
            if (event.window == controller.window) [controller.canvas consumeNativeEvent:event];
            return event;
        }];
}
@end
