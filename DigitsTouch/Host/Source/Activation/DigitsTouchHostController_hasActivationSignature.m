#import "DigitsTouchHostController.h"
#import <Security/Security.h>

@implementation DigitsTouchHostController (ActivationSignature)
- (BOOL)hasActivationSignature {
    SecCodeRef code = NULL;
    CFDictionaryRef information = NULL;
    if (SecCodeCopySelf(kSecCSDefaultFlags, &code) != errSecSuccess)
        return NO;
    OSStatus result = SecCodeCopySigningInformation(code, kSecCSSigningInformation, &information);
    CFRelease(code);
    if (result != errSecSuccess || !information)
        return NO;
    NSDictionary *signing = CFBridgingRelease(information);
    NSDictionary *entitlements = signing[(__bridge NSString *)kSecCodeInfoEntitlementsDict];
    NSString *teamIdentifier = signing[(__bridge NSString *)kSecCodeInfoTeamIdentifier];
#if DEBUG && defined(DIGITS_DEVELOPMENT_USERCLIENT_ACCESS) && \
    DIGITS_DEVELOPMENT_USERCLIENT_ACCESS == 1 && defined(DIGITS_DEVELOPMENT_TEAM_IDENTIFIER)
    // This development profile uses the driver's development-only access entitlement.
    // Keep the host identity exact; the driver independently verifies the same signed identity.
    NSString *expectedTeamIdentifier = @DIGITS_DEVELOPMENT_TEAM_IDENTIFIER;
    NSString *expectedApplicationIdentifier =
        [expectedTeamIdentifier stringByAppendingString:@".local.digits.touch.host"];
    NSString *applicationIdentifier = entitlements[@"com.apple.application-identifier"] ?:
        entitlements[@"application-identifier"];
    NSString *signingIdentifier = signing[(__bridge NSString *)kSecCodeInfoIdentifier];
    return expectedTeamIdentifier.length > 0 &&
           [teamIdentifier isEqualToString:expectedTeamIdentifier] &&
           [entitlements[@"com.apple.developer.team-identifier"]
               isEqualToString:expectedTeamIdentifier] &&
           [applicationIdentifier isEqualToString:expectedApplicationIdentifier] &&
           [signingIdentifier isEqualToString:@"local.digits.touch.host"] &&
           [entitlements[@"com.apple.developer.system-extension.install"] boolValue];
#else
    NSArray *allowedDrivers = entitlements[@"com.apple.developer.driverkit.userclient-access"];
    // This is a UI preflight; macOS performs the authoritative signature checks.
    return teamIdentifier.length > 0 &&
           [entitlements[@"com.apple.developer.system-extension.install"] boolValue] &&
           [allowedDrivers isKindOfClass:NSArray.class] &&
           [allowedDrivers containsObject:@"local.digits.touch"];
#endif
}
@end
