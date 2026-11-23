#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (AutomaticBindingState)
- (void)refreshAutomaticBindingState {
    // The USB driver reads metadata published by Digits Driver. This UI never
    // registers a login item, starts a daemon, or changes a driver configuration.
    self.automaticAssociationState =
        @"Saved display binding loads with Digits Driver. No background helper is required.";
}
@end
