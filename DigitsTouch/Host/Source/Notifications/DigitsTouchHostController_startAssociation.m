#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (AssociationStartup)
- (void)startAssociation {
    if (self.monitoring)
        return;
    if (!self.associationOnly)
        [NSDistributedNotificationCenter.defaultCenter addObserver:self
            selector:@selector(associationChanged:) name:@"local.digits.touch.association.changed"
            object:nil suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
    self.notificationPort = IONotificationPortCreate(kIOMainPortDefault);
    if (!self.notificationPort) {
        self.associationState = @"Could not subscribe to driver arrivals. No display is bound.";
        return;
    }
    IONotificationPortSetDispatchQueue(self.notificationPort, dispatch_get_main_queue());
    io_iterator_t arrivalIterator = IO_OBJECT_NULL;
    io_iterator_t terminationIterator = IO_OBJECT_NULL;
    kern_return_t arrivalResult = IOServiceAddMatchingNotification(
        self.notificationPort, kIOFirstMatchNotification,
        DigitsTouchCreateTransportMatchingDictionary(), DigitsTouchServicesChanged,
        (__bridge void *)self, &arrivalIterator);
    self.arrivalIterator = arrivalIterator;
    kern_return_t terminationResult = IOServiceAddMatchingNotification(
        self.notificationPort, kIOTerminatedNotification,
        DigitsTouchCreateTransportMatchingDictionary(), DigitsTouchServicesChanged,
        (__bridge void *)self, &terminationIterator);
    self.terminationIterator = terminationIterator;
    BOOL displaySubscribed = YES;
    if (self.systemAssociation) {
        NSMutableArray<NSNumber *> *displayIterators = [NSMutableArray array];
        // Physical registry notifications are available in the system bootstrap before
        // login. Do not connect this worker to a user's CoreGraphics/WindowServer session.
        for (NSString *serviceClass in @[ @"IOPortTransportStateDisplayPort", @"AppleDisplay" ]) {
            for (NSString *notification in @[ @kIOFirstMatchNotification, @kIOTerminatedNotification ]) {
                io_iterator_t iterator = IO_OBJECT_NULL;
                kern_return_t result = IOServiceAddMatchingNotification(self.notificationPort,
                    notification.UTF8String, IOServiceMatching(serviceClass.UTF8String),
                    DigitsTouchServicesChanged, (__bridge void *)self, &iterator);
                if (result == KERN_SUCCESS)
                    [displayIterators addObject:@(iterator)];
                else
                    displaySubscribed = NO;
            }
        }
        self.displayEventIterators = displayIterators;
    } else {
        CGError displayResult = CGDisplayRegisterReconfigurationCallback(
            DigitsTouchDisplayChanged, (__bridge void *)self);
        self.displayCallbackRegistered = displayResult == kCGErrorSuccess;
        displaySubscribed = self.displayCallbackRegistered;
    }
    if (arrivalResult != KERN_SUCCESS || terminationResult != KERN_SUCCESS ||
        !displaySubscribed) {
        self.associationState =
            @"Display or driver event subscription failed. No display is bound.";
        [self stopAssociation];
        return;
    }
    self.monitoring = YES;
    DigitsTouchServicesChanged((__bridge void *)self, self.arrivalIterator);
    DigitsTouchServicesChanged((__bridge void *)self, self.terminationIterator);
    for (NSNumber *iterator in self.displayEventIterators)
        DigitsTouchServicesChanged((__bridge void *)self, iterator.unsignedIntValue);
}
@end
