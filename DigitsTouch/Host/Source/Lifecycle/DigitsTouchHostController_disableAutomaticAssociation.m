#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (AutomaticAssociationDisable)
- (BOOL)disableAutomaticAssociation {
    SMAppService *service =
        [SMAppService agentServiceWithPlistName:@"local.digits.touch.association.plist"];
    if (service.status == SMAppServiceStatusNotRegistered ||
        service.status == SMAppServiceStatusNotFound)
        return YES;
    NSError *error = nil;
    if (![service unregisterAndReturnError:&error]) {
        self.automaticAssociationState = [NSString stringWithFormat:
            @"Automatic Touch could not stop: %@ (%@ %ld).", error.localizedDescription,
            error.domain, (long)error.code];
        return NO;
    }
    self.automaticAssociationState = @"Automatic Touch is disabled.";
    return YES;
}
@end
