#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (ReadStatus)
- (void)refreshStatus {
    self.savedDisplayUUID = DigitsReadSavedDisplayUUID();
    NSArray<DigitsDisplayOption *> *displays = DigitsCopyDisplayOptions();
    NSDictionary *driver = DigitsCopyServiceProperties(@"XeneonEarlyInitControl", nil);
    NSDictionary *touch = DigitsCopyTouchRuntimeState();
    self.activeDisplayUUID = [touch[@"ActiveDisplayUUID"] isKindOfClass:NSString.class] ? touch[@"ActiveDisplayUUID"] : nil;
    NSString *activeName = nil;
    for (DigitsDisplayOption *display in displays) {
        if ([display.displayUUID isEqualToString:self.activeDisplayUUID])
            activeName = display.name;
    }
    self.bindingPendingRestart = self.savedDisplayUUID && ![self.savedDisplayUUID isEqualToString:self.activeDisplayUUID];
    self.bindingLabel.stringValue = @"Native touch that works as it should";
    NSString *driverVersion = [driver[@"DriverVersion"] isKindOfClass:NSString.class] ? driver[@"DriverVersion"] : @"—";
    NSString *touchVersion = [touch[@"DriverVersion"] isKindOfClass:NSString.class] ? touch[@"DriverVersion"] : @"—";
    BOOL touchActive = [touch[@"BindingState"] isEqual:@"Native touch active"];
    BOOL driverReady = [driver[@"DriverBundleIdentifier"] isEqual:@"local.digits.driver"] &&
        [driver[@"Armed"] boolValue] && [driver[@"HookInstalled"] boolValue];
    self.testerAvailable = driverReady && activeName != nil;
    self.testerButton.enabled = !self.operationInProgress && self.testerAvailable;
    NSString *appVersion = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"0.2.3";
    self.footerLabel.stringValue = [NSString stringWithFormat:@"Digits %@    ·    Touch %@ · %@    ·    Driver %@ · %@", appVersion, touchVersion, touchActive ? @"Active" : (touch.count ? @"Connected" : @"Not attached"), driverVersion, driverReady ? @"Armed" : (driver.count ? @"Loaded, not armed" : @"Not loaded")];
    self.statusLabel.stringValue = self.bindingPendingRestart ? @"Display binding saved. Restart to apply." : (self.testerAvailable ? (touchActive ? @"Touch is ready. Digits can be closed." : @"Open Tester to check your touch experience.") : @"Waiting for your touch display and its drivers.");
}
@end
