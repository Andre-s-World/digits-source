#import "DigitsTests.h"
@implementation DigitsTestsReportObserver (Start)
- (BOOL)startForDisplayUUID:(NSString *)uuid canvas:(DigitsTestsCanvas *)canvas error:(NSError **)error
{
    [self stop];
    NSDictionary *preflight = [DigitsTestsReportObserver preflightForDisplayUUID:uuid];
    if (![preflight[@"eligible"] boolValue]) {
        if (error) *error = [NSError errorWithDomain:@"DigitsTesterReports" code:1
            userInfo:@{NSLocalizedDescriptionKey:preflight[@"reason"]}];
        return NO;
    }
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault,
        IORegistryEntryIDMatching([preflight[@"registryID"] unsignedLongLongValue]));
    if (service) self.device = IOHIDDeviceCreate(kCFAllocatorDefault, service);
    if (service) IOObjectRelease(service);
    if (!self.device) return NO;
    self.canvas = canvas;
    self.reportBuffer = [NSMutableData dataWithLength:54];
    IOHIDDeviceRegisterInputReportCallback(self.device, self.reportBuffer.mutableBytes, 54,
        DigitsTestsInputReportReceived, (__bridge void *)self);
    // Options zero is shared, never seize. No feature/output requests are sent.
    // The registry preflight rejects protected HID collections before this call.
    IOReturn result = IOHIDDeviceOpen(self.device, kIOHIDOptionsTypeNone);
    if (result != kIOReturnSuccess) {
        if (error) *error = [NSError errorWithDomain:@"DigitsTesterReports" code:result
            userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"Touch report observation unavailable (0x%08x).", result]}];
        [self stop];
        return NO;
    }
    self.opened = YES;
    IOHIDDeviceScheduleWithRunLoop(self.device, CFRunLoopGetMain(), kCFRunLoopCommonModes);
    canvas.reportObserverStatus = @"Digits Touch · normalized 0D · pressure unavailable";
    return YES;
}
@end
