#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (StopStatusObservation)
- (void)stopStatusObservation {
    self.statusObservationActive = NO;
    self.statusRefreshDeferred = NO;
    self.statusRefreshScheduled = NO;
    if (self.screenChangeToken) {
        [NSNotificationCenter.defaultCenter removeObserver:self.screenChangeToken];
        self.screenChangeToken = nil;
    }
    if (self.workspaceWakeToken) {
        [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self.workspaceWakeToken];
        self.workspaceWakeToken = nil;
    }
    // Detach the queue before releasing registrations. Queued refresh blocks
    // check statusObservationActive so uninstall cannot revive its controls.
    if (self.statusNotificationPort)
        IONotificationPortSetDispatchQueue(self.statusNotificationPort, NULL);
    for (NSNumber *iterator in self.statusNotificationIterators)
        IOObjectRelease(iterator.unsignedIntValue);
    [self.statusNotificationIterators removeAllObjects];
    if (self.statusNotificationPort) {
        IONotificationPortDestroy(self.statusNotificationPort);
        self.statusNotificationPort = NULL;
    }
}
@end
