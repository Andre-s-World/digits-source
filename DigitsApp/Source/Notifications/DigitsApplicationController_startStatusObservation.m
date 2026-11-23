#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (StartStatusObservation)
- (void)startStatusObservation {
    if (self.statusObservationActive)
        return;
    self.statusObservationActive = YES;
    self.statusNotificationIterators = [NSMutableArray new];
    self.statusNotificationPort = IONotificationPortCreate(kIOMainPortDefault);
    if (self.statusNotificationPort) {
        // Only our transport, native child and existing driver control publish
        // status relevant to Tester. These registrations never open a device.
        IONotificationPortSetDispatchQueue(self.statusNotificationPort, dispatch_get_main_queue());
        NSArray<NSDictionary *> *identities = @[
            @{@"class":@"IOUserService", @"properties":@{
                @"IOUserClass":@"DigitsUSBTransport", @"IOUserServerName":@"local.digits.touch"}},
            @{@"name":@"DigitsTouchDevice"},
            @{@"class":@"XeneonEarlyInitControl"}
        ];
        const char *notificationTypes[] = {kIOFirstMatchNotification, kIOTerminatedNotification};
        for (NSDictionary *identity in identities) {
            for (NSUInteger index = 0; index < 2; ++index) {
                NSString *name = identity[@"name"];
                CFMutableDictionaryRef matching = name ? IOServiceNameMatching(name.UTF8String) :
                    IOServiceMatching([identity[@"class"] UTF8String]);
                if (!matching)
                    continue;
                NSDictionary *properties = identity[@"properties"];
                if (properties)
                    CFDictionarySetValue(matching, CFSTR(kIOPropertyMatchKey),
                                         (__bridge CFDictionaryRef)properties);
                io_iterator_t iterator = IO_OBJECT_NULL;
                kern_return_t result = IOServiceAddMatchingNotification(self.statusNotificationPort,
                    notificationTypes[index], matching, DigitsStatusRegistryChanged,
                    (__bridge void *)self, &iterator);
                if (result == KERN_SUCCESS) {
                    [self.statusNotificationIterators addObject:@(iterator)];
                    // Draining also arms delivery of subsequent notifications.
                    DigitsStatusRegistryChanged((__bridge void *)self, iterator);
                } else if (iterator) {
                    IOObjectRelease(iterator);
                }
            }
        }
    }
    __weak DigitsApplicationController *weakSelf = self;
    self.screenChangeToken = [NSNotificationCenter.defaultCenter
        addObserverForName:NSApplicationDidChangeScreenParametersNotification object:nil
        queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *notification) {
            (void)notification;
            [weakSelf scheduleStatusRefresh];
        }];
    self.workspaceWakeToken = [NSWorkspace.sharedWorkspace.notificationCenter
        addObserverForName:NSWorkspaceDidWakeNotification object:nil
        queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *notification) {
            (void)notification;
            [weakSelf scheduleStatusRefresh];
        }];
}
@end
