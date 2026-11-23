#import "DigitsTests.h"
@implementation DigitsTestsReportObserver (Stop)
- (void)stop
{
    if (self.device) {
        // Remove only our shared callback; WindowServer's device link is untouched.
        IOHIDDeviceUnscheduleFromRunLoop(self.device, CFRunLoopGetMain(), kCFRunLoopCommonModes);
        IOHIDDeviceRegisterInputReportCallback(self.device, self.reportBuffer.mutableBytes, 54, NULL, NULL);
        if (self.opened) IOHIDDeviceClose(self.device, kIOHIDOptionsTypeNone);
        CFRelease(self.device);
        self.device = NULL;
    }
    self.opened = NO;
    self.reportBuffer = nil;
    self.canvas = nil;
}
@end
