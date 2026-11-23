#import "DigitsTouchHostController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsTouchHostController (Approval)
- (void)requestNeedsUserApproval:(OSSystemExtensionRequest *)request {
    (void)request;
    self.activationState = @"Approve Digits Touch in System Settings to continue.";
    [self updateStatus];
}
@end
#pragma clang diagnostic pop
