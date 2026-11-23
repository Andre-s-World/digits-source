#import "DigitsApplicationOperations.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsApplicationOperations (RequestFinished)
- (void)request:(OSSystemExtensionRequest *)request didFinishWithResult:(OSSystemExtensionRequestResult)result {
    (void)request;
    (void)result;
    DigitsActionCompletion completion = self.uninstallCompletion;
    self.uninstallCompletion = nil;
    if (completion)
        [self runMaintenanceAction:@"--uninstall" argument:@"" completion:completion];
}
@end
#pragma clang diagnostic pop
