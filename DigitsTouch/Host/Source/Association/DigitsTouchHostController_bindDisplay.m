#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (DisplayBinding)
- (void)bindDisplay:(DigitsTouchDisplayIdentity *)display {
    NSString *bindingIdentity =
        [NSString stringWithFormat:@"%llu:%llu:%u:%@", self.connectedTransportRegistryID,
                                   self.connectedPhysicalUSBRegistryID, display.displayID,
                                   display.displayUUID];
    if ([self.activeBindingIdentity isEqualToString:bindingIdentity])
        return;
    if (self.activeBindingIdentity.length > 0) {
        kern_return_t unbindResult = IOConnectCallScalarMethod(
            self.driverConnection, kDigitsTouchUnbindDisplay, NULL, 0, NULL, NULL);
        if (unbindResult != KERN_SUCCESS) {
            self.associationState = @"The previous display binding could not be released.";
            [self disconnectTransport];
            return;
        }
        self.activeBindingIdentity = nil;
    }
    DigitsTouchDisplayBinding binding = {0};
    binding.version = kDigitsTouchProtocolVersion;
    binding.displayID = display.displayID;
    binding.physicalUSBRegistryID = self.connectedPhysicalUSBRegistryID;
    if (![display.displayUUID getCString:binding.displayUUID
                               maxLength:sizeof(binding.displayUUID)
                                encoding:NSASCIIStringEncoding]) {
        self.associationState = @"The current display UUID could not be encoded.";
        return;
    }
    kern_return_t result = IOConnectCallStructMethod(self.driverConnection, kDigitsTouchBindDisplay,
                                                     &binding, sizeof(binding), NULL, NULL);
    if (result != KERN_SUCCESS) {
        self.associationState =
            [NSString stringWithFormat:@"Display association was rejected (0x%08x).", result];
        return;
    }
    self.activeBindingIdentity = bindingIdentity;
    self.associationState =
        [NSString stringWithFormat:@"%@ is associated with its current display.\nDisplay UUID: %@",
                                   display.productName, display.displayUUID];
}
@end
