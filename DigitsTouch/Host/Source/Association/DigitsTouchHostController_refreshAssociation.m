#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (AssociationRefresh)
- (void)refreshAssociation {
    NSArray<NSDictionary *> *transports = [self copyTransportIdentities];
    NSArray<DigitsTouchDisplayIdentity *> *physicalDisplays = [self copyPhysicalDisplays];
    if (transports.count != 1 || physicalDisplays.count != 1) {
        [self pauseAssociation];
        self.associationState =
            transports.count > 1 || physicalDisplays.count > 1
                ? @"Multiple matching panels are ambiguous. Touch is not bound."
                : @"Waiting for the physical display and Digits Touch to attach. Enabling the extension does not confirm USB attachment.";
        [self updateStatus];
        return;
    }
    if (!self.associationOnly) {
        // The system helper is the sole metadata owner. The GUI reports the actual
        // transport state even when this user has never created a configuration file.
        self.associationState = [NSString stringWithFormat:@"%@ · %@",
            physicalDisplays[0].productName, transports[0][@"BindingState"]];
        [self updateStatus];
        return;
    }
    NSDictionary *configuration = [self loadDigitsDisplayBinding];
    if (!configuration) {
        [self pauseAssociation];
        [self updateStatus];
        return;
    }
    DigitsTouchDisplayIdentity *display = physicalDisplays[0];
    if (self.systemAssociation) {
        if (display.vendorID != [configuration[@"DisplayVendorID"] unsignedIntValue] ||
            display.productID != [configuration[@"DisplayProductID"] unsignedIntValue] ||
            display.serialNumber != [configuration[@"DisplaySerialNumber"] unsignedIntValue] ||
            [display.EDIDSHA256 caseInsensitiveCompare:configuration[@"DisplayEDIDSHA256"]] !=
                NSOrderedSame) {
            [self pauseAssociation];
            self.associationState = @"The system display binding does not match the connected panel's EDID. Touch stays unbound.";
            [self updateStatus];
            return;
        }
        // WindowServer routes native HID by this saved display UUID. A session-local
        // CGDirectDisplayID is not required and is deliberately zero before login.
        display.displayUUID = configuration[@"DisplayUUID"];
        display.displayID = 0;
    } else {
        display = [self currentDisplayForIdentity:display];
        if (!display || [display.displayUUID caseInsensitiveCompare:configuration[@"DisplayUUID"]]
            != NSOrderedSame) {
            [self pauseAssociation];
            if (display)
                self.associationState = @"The saved display UUID does not match the physical panel. Touch stays unbound.";
            [self updateStatus];
            return;
        }
    }
    if ([self connectTransport:transports[0]])
        [self bindDisplay:display];
    [self updateStatus];
}
@end
