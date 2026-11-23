#import "DigitsInstallerActivationSession.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsInstallerActivationSession (Approval)
- (void)requestNeedsUserApproval:(OSSystemExtensionRequest *)request {
    (void)request;
    [self emitEvent:@{@"event": @"needsApproval", @"message":
        @"Allow Digits in System Settings → General → Login Items & Extensions → Driver Extensions."}];
}
@end
#pragma clang diagnostic pop
