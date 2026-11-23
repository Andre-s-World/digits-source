#import "DigitsApplicationOperations.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsApplicationOperations (RequestReplacement)
- (OSSystemExtensionReplacementAction)request:(OSSystemExtensionRequest *)request
    actionForReplacingExtension:(OSSystemExtensionProperties *)existing
                  withExtension:(OSSystemExtensionProperties *)extension {
    (void)request;
    (void)existing;
    (void)extension;
    // This configuration app never upgrades a working DriverKit extension.
    return OSSystemExtensionReplacementActionCancel;
}
@end
#pragma clang diagnostic pop
