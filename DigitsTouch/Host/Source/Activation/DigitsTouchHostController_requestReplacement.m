#import "DigitsTouchHostController.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsTouchHostController (Replacement)
- (OSSystemExtensionReplacementAction)request:(OSSystemExtensionRequest *)request
                  actionForReplacingExtension:(OSSystemExtensionProperties *)existing
                                withExtension:(OSSystemExtensionProperties *)replacement {
    (void)request;
    (void)existing;
    (void)replacement;
    return self.activationRequested ? OSSystemExtensionReplacementActionReplace
                                    : OSSystemExtensionReplacementActionCancel;
}
@end
#pragma clang diagnostic pop
