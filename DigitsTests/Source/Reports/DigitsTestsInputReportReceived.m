#import "DigitsTests.h"
void DigitsTestsInputReportReceived(void *context, IOReturn result, void *sender,
    IOHIDReportType type, uint32_t reportID, uint8_t *report, CFIndex length)
{
    (void)sender;
    if (!context) return;
    DigitsTestsReportObserver *observer = (__bridge DigitsTestsReportObserver *)context;
    NSString *status = @"Digits Touch · normalized 0D · pressure unavailable";
    NSData *snapshot = nil;
    if (result != kIOReturnSuccess) {
        status = [NSString stringWithFormat:@"Touch stream callback failed (0x%08x).", result];
    } else if (type != kIOHIDReportTypeInput || reportID != 0x0d || length != 54) {
        status = [NSString stringWithFormat:@"Touch stream rejected: type %u, ID %02x, %ld bytes.",
            (unsigned)type, reportID, (long)length];
    } else if (!report || report[0] != 0x0d) {
        status = @"Touch stream rejected: missing normalized 0D report header.";
    } else {
        snapshot = [NSData dataWithBytes:report length:(NSUInteger)length];
    }
    __weak DigitsTestsReportObserver *weakObserver = observer;
    void (^deliver)(void) = ^{
        DigitsTestsCanvas *canvas = weakObserver.canvas;
        if (!canvas) return;
        // Keep one current status instead of appending an error per report.
        // A later valid frame clears a transient rejection without logging data.
        if (![canvas.reportObserverStatus isEqualToString:status]) {
            canvas.reportObserverStatus = status;
            [canvas setNeedsDisplay:YES];
        }
        if (snapshot) [canvas consumeNormalizedReport:snapshot];
    };
    // This connection is scheduled on the main run loop. Keep that UI contract
    // explicit even if a framework callback arrives on another thread.
    if (NSThread.isMainThread) deliver();
    else dispatch_async(dispatch_get_main_queue(), deliver);
}
