#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (Controls)
- (void)updateControls {
    self.statusLabel.stringValue = self.statusMessage ?: @"";
    self.primaryButton.enabled = !self.busy;
    self.secondaryButton.enabled = !self.busy;
    self.backButton.enabled = !self.busy;
    self.backButton.hidden = self.step != DigitsInstallerStepDisplay;
    self.secondaryButton.hidden = YES;
    NSString *title = @"Next";
    NSString *symbol = @"arrow.right";
    if (self.step == DigitsInstallerStepIntroduction) {
        title = self.existingInstallation ? @"Reinstall" : @"Next";
        symbol = self.existingInstallation ? @"arrow.clockwise" : @"arrow.right";
        self.primaryButton.enabled = self.inspectionComplete && !self.busy;
        self.secondaryButton.hidden = !self.existingInstallation;
        self.secondaryButton.title = @"Uninstall";
        self.secondaryButton.image = [NSImage imageWithSystemSymbolName:@"trash" accessibilityDescription:nil];
        self.secondaryButton.enabled = !self.previewOnly && !self.busy;
    } else if (self.step == DigitsInstallerStepDisplay) {
        title = @"Install";
        symbol = @"arrow.down.circle";
        self.primaryButton.enabled = !self.previewOnly && !self.busy && self.selectedDisplayUUID.length > 0;
        self.secondaryButton.hidden = NO;
        self.secondaryButton.title = @"Refresh Displays";
        self.secondaryButton.image = [NSImage imageWithSystemSymbolName:@"arrow.clockwise" accessibilityDescription:nil];
    } else if (self.step == DigitsInstallerStepApplication) {
        title = @"Retry";
        symbol = @"arrow.clockwise";
        self.primaryButton.enabled = !self.previewOnly && !self.busy;
    } else if (self.step == DigitsInstallerStepTouch) {
        title = @"Enable Digits Touch";
        symbol = @"hand.point.up.left";
        self.primaryButton.enabled = !self.previewOnly && !self.busy;
    } else if (self.step == DigitsInstallerStepDriver) {
        title = self.driverInstalled ? @"Check Approval" : @"Install Digits Driver";
        symbol = self.driverInstalled ? @"checkmark.shield" : @"arrow.down.circle";
        self.primaryButton.enabled = !self.previewOnly && !self.busy;
        self.passwordConfirmation.enabled = !self.previewOnly && !self.busy && self.driverInstalled;
    } else if (self.step == DigitsInstallerStepFinished) {
        title = @"Reboot";
        symbol = @"restart";
        self.primaryButton.enabled = !self.previewOnly;
        self.secondaryButton.hidden = NO;
        self.secondaryButton.title = @"Restart Later";
        self.secondaryButton.image = [NSImage imageWithSystemSymbolName:@"clock" accessibilityDescription:nil];
    }
    if (self.previewOnly) {
        title = self.step == DigitsInstallerStepFinished ? @"Close Preview" : @"Preview Next";
        symbol = self.step == DigitsInstallerStepFinished ? @"xmark" : @"arrow.right";
        self.primaryButton.enabled = !self.busy;
        self.secondaryButton.hidden = YES;
        self.backButton.hidden = self.step == DigitsInstallerStepIntroduction;
    }
    self.primaryButton.title = title;
    self.primaryButton.image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:nil];
    if (self.busy)
        [self.activityIndicator startAnimation:nil];
    else
        [self.activityIndicator stopAnimation:nil];
}
@end
