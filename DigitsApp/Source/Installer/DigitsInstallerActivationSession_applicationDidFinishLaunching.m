#import "DigitsInstallerActivationSession.h"

@implementation DigitsInstallerActivationSession (Launch)
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    NSString *message = nil;
    if (!DigitsInstallerHostIsValid(&message)) {
        [self finishWithEvent:@{@"event": @"failed", @"message": message} status:2];
        return;
    }
    self.request = self.activation ?
        [OSSystemExtensionRequest activationRequestForExtension:@"local.digits.touch" queue:dispatch_get_main_queue()] :
        [OSSystemExtensionRequest deactivationRequestForExtension:@"local.digits.touch" queue:dispatch_get_main_queue()];
    self.request.delegate = self;
    [self emitEvent:@{@"event": @"submitted", @"message": self.activation ?
        @"Requesting macOS approval for Digits Touch." : @"Requesting removal of Digits Touch."}];
    [OSSystemExtensionManager.sharedManager submitRequest:self.request];
}
@end
