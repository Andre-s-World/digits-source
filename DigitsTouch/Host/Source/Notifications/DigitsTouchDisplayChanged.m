#import "DigitsTouchHostController.h"

void DigitsTouchDisplayChanged(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags,
                               void *context) {
    (void)display;
    if (flags & kCGDisplayBeginConfigurationFlag)
        return;
    DigitsTouchHostController *controller = (__bridge DigitsTouchHostController *)context;
    [controller scheduleAssociationRefresh];
}
