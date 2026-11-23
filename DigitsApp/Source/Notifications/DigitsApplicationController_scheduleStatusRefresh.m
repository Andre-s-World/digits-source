#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (ScheduleStatusRefresh)
- (void)scheduleStatusRefresh {
    if (!self.statusObservationActive)
        return;
    if (self.operationInProgress) {
        self.statusRefreshDeferred = YES;
        return;
    }
    if (self.statusRefreshScheduled)
        return;
    self.statusRefreshScheduled = YES;
    // Match/termination events can arrive together during reconnect. One
    // main-queue refresh reads their final state without a polling timer.
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusRefreshScheduled = NO;
        if (!self.statusObservationActive)
            return;
        if (self.operationInProgress) {
            self.statusRefreshDeferred = YES;
            return;
        }
        self.statusRefreshDeferred = NO;
        [self refreshStatus];
        if (self.displayPanelOpen)
            [self refreshDisplayOptions];
    });
}
@end
