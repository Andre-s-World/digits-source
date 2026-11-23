#import "DigitsApplicationOperations.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsApplicationOperations (RequestApproval)
- (void)requestNeedsUserApproval:(OSSystemExtensionRequest *)request {
    (void)request;
    [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:
        @"x-apple.systempreferences:com.apple.LoginItems-Settings.extension"]];
}
@end
#pragma clang diagnostic pop
