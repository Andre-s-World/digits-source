#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (Status)
- (void)updateStatus {
    self.statusLabel.stringValue = [NSString
        stringWithFormat:@"%@\n%@\n%@", self.associationState ?: @"", self.activationState ?: @"",
                         self.automaticAssociationState ?: @""];
    self.activateButton.enabled = self.signedForActivation && !self.extensionRequestPending;
    self.deactivateButton.enabled = self.signedForActivation && !self.extensionRequestPending;
    if (self.associationOnly) {
        NSLog(@"Digits Touch: %@", self.associationState);
        if (!self.systemAssociation)
            [NSDistributedNotificationCenter.defaultCenter postNotificationName:
                @"local.digits.touch.association.changed" object:nil userInfo:nil
                options:NSNotificationDeliverImmediately];
    }
}
@end
