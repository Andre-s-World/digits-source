#import "DigitsInstallerActivationSession.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsInstallerActivationSession (Accepted)
- (void)request:(OSSystemExtensionRequest *)request didFinishWithResult:(OSSystemExtensionRequestResult)result {
    (void)request;
    BOOL reboot = result == OSSystemExtensionRequestWillCompleteAfterReboot;
    NSString *message = reboot ? @"macOS accepted the request. It will complete after the final restart." :
        (self.activation ? @"macOS enabled Digits Touch." : @"macOS removed Digits Touch.");
    [self finishWithEvent:@{@"event": @"complete", @"approved": @YES,
        @"restartRequired": @(reboot), @"message": message} status:0];
}
@end
#pragma clang diagnostic pop
