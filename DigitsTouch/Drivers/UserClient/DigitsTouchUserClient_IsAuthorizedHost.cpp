#include "DigitsTouchUserClientState.hpp"
bool DigitsTouchUserClient::IsAuthorizedHost() {
    OSDictionary *entitlements = nullptr;
    if (CopyClientEntitlements(&entitlements) != kIOReturnSuccess || !entitlements) return false;
    OSArray *access = OSDynamicCast(OSArray,
        entitlements->getObject("com.apple.developer.driverkit.userclient-access"));
    bool hasNarrowAccess = false;
    if (access) {
        for (unsigned int index = 0; index < access->getCount(); ++index) {
            OSString *identifier = OSDynamicCast(OSString, access->getObject(index));
            if (identifier && strcmp(identifier->getCStringNoCopy(), "local.digits.touch") == 0)
                hasNarrowAccess = true;
        }
    }
    bool isAuthorized = hasNarrowAccess;
#if defined(DIGITS_DEVELOPMENT_USERCLIENT_ACCESS) && \
    DIGITS_DEVELOPMENT_USERCLIENT_ACCESS == 1 && defined(DIGITS_DEVELOPMENT_TEAM_IDENTIFIER)
    // The development OS gate is broader; our client gate remains this exact signed host.
    // An empty team disables the fallback, and conflicting application-ID aliases fail closed.
    if (!isAuthorized) {
        const char *expectedTeam = DIGITS_DEVELOPMENT_TEAM_IDENTIFIER;
        const char *expectedApplication =
            DIGITS_DEVELOPMENT_TEAM_IDENTIFIER ".local.digits.touch.host";
        OSString *team = OSDynamicCast(OSString,
            entitlements->getObject("com.apple.developer.team-identifier"));
        OSObject *modernValue = entitlements->getObject("com.apple.application-identifier");
        OSObject *legacyValue = entitlements->getObject("application-identifier");
        OSString *modernIdentifier = OSDynamicCast(OSString, modernValue);
        OSString *legacyIdentifier = OSDynamicCast(OSString, legacyValue);
        const bool modernMatches = modernIdentifier &&
            strcmp(modernIdentifier->getCStringNoCopy(), expectedApplication) == 0;
        const bool legacyMatches = legacyIdentifier &&
            strcmp(legacyIdentifier->getCStringNoCopy(), expectedApplication) == 0;
        isAuthorized = expectedTeam[0] != '\0' && team &&
            strcmp(team->getCStringNoCopy(), expectedTeam) == 0 &&
            (modernValue || legacyValue) && (!modernValue || modernMatches) &&
            (!legacyValue || legacyMatches);
    }
#endif
    // Production keeps the original narrow entitlement contract, with no development fallback.
    entitlements->release();
    return isAuthorized;
}
