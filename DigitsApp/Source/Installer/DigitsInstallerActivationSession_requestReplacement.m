#import "DigitsInstallerActivationSession.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsInstallerActivationSession (Replacement)
- (OSSystemExtensionReplacementAction)request:(OSSystemExtensionRequest *)request
        actionForReplacingExtension:(OSSystemExtensionProperties *)existing
        withExtension:(OSSystemExtensionProperties *)replacement {
    (void)request;
    // Reinstall replaces only our bundled, frozen Touch version. Never accept
    // an unrelated extension or downgrade a newer installation silently.
    BOOL allowed = self.activation &&
        [existing.bundleIdentifier isEqualToString:@"local.digits.touch"] &&
        [replacement.bundleIdentifier isEqualToString:@"local.digits.touch"] &&
        [replacement.bundleVersion isEqualToString:@"0.1.6"] &&
        [existing.bundleVersion compare:replacement.bundleVersion options:NSNumericSearch] != NSOrderedDescending;
    return allowed ? OSSystemExtensionReplacementActionReplace : OSSystemExtensionReplacementActionCancel;
}
@end
#pragma clang diagnostic pop
