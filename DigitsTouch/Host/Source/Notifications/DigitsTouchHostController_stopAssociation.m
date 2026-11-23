#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (AssociationShutdown)
- (void)stopAssociation {
    [NSDistributedNotificationCenter.defaultCenter removeObserver:self
        name:@"local.digits.touch.association.changed" object:nil];
    if (self.displayCallbackRegistered)
        CGDisplayRemoveReconfigurationCallback(DigitsTouchDisplayChanged, (__bridge void *)self);
    self.displayCallbackRegistered = NO;
    for (NSNumber *iterator in self.displayEventIterators)
        IOObjectRelease(iterator.unsignedIntValue);
    self.displayEventIterators = nil;
    for (NSNumber *notification in self.displayInterests.allValues)
        IOObjectRelease(notification.unsignedIntValue);
    self.displayInterests = nil;
    if (self.arrivalIterator)
        IOObjectRelease(self.arrivalIterator);
    if (self.terminationIterator)
        IOObjectRelease(self.terminationIterator);
    self.arrivalIterator = IO_OBJECT_NULL;
    self.terminationIterator = IO_OBJECT_NULL;
    if (self.notificationPort) {
        IONotificationPortSetDispatchQueue(self.notificationPort, NULL);
        IONotificationPortDestroy(self.notificationPort);
        self.notificationPort = NULL;
    }
    self.monitoring = NO;
    [self disconnectTransport];
}
@end
