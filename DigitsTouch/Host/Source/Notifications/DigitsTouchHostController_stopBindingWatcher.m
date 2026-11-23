#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (BindingWatchShutdown)
- (void)stopBindingWatcher {
    if (self.bindingWatcher) {
        dispatch_source_cancel(self.bindingWatcher);
        self.bindingWatcher = nil;
    }
}
@end
