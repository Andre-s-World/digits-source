#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (StageContent)
- (NSView *)makeStageContent {
    NSView *content = [NSView new];
    NSStackView *body = [NSStackView stackViewWithViews:@[]];
    body.orientation = NSUserInterfaceLayoutOrientationVertical;
    body.alignment = NSLayoutAttributeLeading;
    body.spacing = self.step == DigitsInstallerStepDriver ? 12 : 18;
    body.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:body];
    [NSLayoutConstraint activateConstraints:@[
        [body.topAnchor constraintEqualToAnchor:content.topAnchor constant:18],
        [body.leadingAnchor constraintEqualToAnchor:content.leadingAnchor],
        [body.trailingAnchor constraintEqualToAnchor:content.trailingAnchor]
    ]];
    NSArray<NSString *> *titles = @[@"A place for every touch.", @"Give your touches a home.",
        @"Meet Digits.", @"Let touch in.", @"One last permission.",
        self.uninstallCompleted ? @"A clean goodbye." : @"Ready for every touch."];
    NSArray<NSString *> *descriptions = @[
        self.existingInstallation ? @"Digits is already installed. Reinstall it with a new display selection, or remove the whole installation."
            : @"Install Digits, Digits Touch and Digits Driver, with a little guidance at each step.",
        @"Choose the display that belongs to your touchscreen. This is where Digits will send its touches.",
        @"The Digits app and your selected display association are installed together. You can change the display later in Digits.",
        @"Digits Touch translates the digitizer’s reports into native macOS touch.",
        @"Digits Driver prepares the touchscreen during USB startup. This step needs your macOS approval.",
        self.uninstallCompleted ? @"Digits, Digits Touch and Digits Driver have been removed. Restart to finish removing the loaded components."
            : @"Digits, Digits Touch and Digits Driver are installed. Restart your Mac to finish setting everything in motion."
    ];
    NSArray<NSString *> *symbols = @[@"hand.draw", @"display", @"app", @"hand.point.up.left",
        @"checkmark.shield", self.uninstallCompleted ? @"checkmark.circle" : @"sparkles"];
    if (self.step != DigitsInstallerStepDisplay) {
        NSImageView *symbol = [[NSImageView alloc] initWithFrame:NSZeroRect];
        symbol.translatesAutoresizingMaskIntoConstraints = NO;
        symbol.image = [NSImage imageWithSystemSymbolName:symbols[self.step] accessibilityDescription:nil];
        symbol.contentTintColor = self.step == DigitsInstallerStepFinished ? NSColor.systemTealColor : NSColor.systemPurpleColor;
        symbol.imageScaling = NSImageScaleProportionallyUpOrDown;
        [body addArrangedSubview:symbol];
        [symbol.widthAnchor constraintEqualToConstant:49].active = YES;
        [symbol.heightAnchor constraintEqualToConstant:49].active = YES;
    }
    NSTextField *title = DigitsInstallerMakeLabel(titles[self.step], 35, NSFontWeightUltraLight);
    NSTextField *description = DigitsInstallerMakeLabel(descriptions[self.step], 18, NSFontWeightLight);
    description.textColor = NSColor.secondaryLabelColor;
    [body addArrangedSubview:title];
    [body addArrangedSubview:description];
    [title.widthAnchor constraintEqualToAnchor:body.widthAnchor].active = YES;
    [description.widthAnchor constraintEqualToAnchor:body.widthAnchor].active = YES;

    if (self.step == DigitsInstallerStepIntroduction) {
        NSTextField *requirement = DigitsInstallerMakeLabel(
            @"Before you begin\nThis experimental unsigned build requires SIP disabled and Permissive Security with kernel extensions allowed. Reduced Security is insufficient for this build. The installer never changes your security settings.",
            16, NSFontWeightLight);
        NSTextField *restart = DigitsInstallerMakeLabel(@"Keep your touchscreen connected. A restart will complete installation.",
            16, NSFontWeightLight);
        [body addArrangedSubview:requirement];
        [body addArrangedSubview:restart];
        [requirement.widthAnchor constraintEqualToAnchor:body.widthAnchor].active = YES;
        [restart.widthAnchor constraintEqualToAnchor:body.widthAnchor].active = YES;
    } else if (self.step == DigitsInstallerStepDisplay) {
        NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
        scroll.translatesAutoresizingMaskIntoConstraints = NO;
        scroll.drawsBackground = NO;
        scroll.hasVerticalScroller = YES;
        scroll.borderType = NSNoBorder;
        NSStackView *list = [NSStackView stackViewWithViews:@[]];
        list.orientation = NSUserInterfaceLayoutOrientationVertical;
        list.alignment = NSLayoutAttributeLeading;
        list.spacing = 9;
        list.translatesAutoresizingMaskIntoConstraints = NO;
        for (NSUInteger index = 0; index < self.displayOptions.count; index++) {
            DigitsInstallerDisplayOption *option = self.displayOptions[index];
            NSButton *row = [NSButton radioButtonWithTitle:option.name target:self action:@selector(selectDisplay:)];
            row.translatesAutoresizingMaskIntoConstraints = NO;
            row.tag = (NSInteger)index;
            row.state = [option.displayUUID isEqualToString:self.selectedDisplayUUID] ? NSControlStateValueOn : NSControlStateValueOff;
            NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:
                [NSString stringWithFormat:@"%@\n%@", option.name, option.detail]];
            [text addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:16 weight:NSFontWeightLight],
                NSForegroundColorAttributeName:NSColor.labelColor} range:NSMakeRange(0, option.name.length)];
            [text addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:12 weight:NSFontWeightLight],
                NSForegroundColorAttributeName:NSColor.secondaryLabelColor}
                range:NSMakeRange(option.name.length, text.length-option.name.length)];
            row.attributedTitle = text;
            row.cell.wraps = YES;
            row.cell.lineBreakMode = NSLineBreakByWordWrapping;
            row.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", option.name, option.detail];
            [list addArrangedSubview:row];
            [row.widthAnchor constraintEqualToAnchor:list.widthAnchor].active = YES;
            [row.heightAnchor constraintGreaterThanOrEqualToConstant:74].active = YES;
        }
        if (!self.displayOptions.count) {
            NSTextField *none = DigitsInstallerMakeLabel(@"No display is available. Connect your touchscreen, then refresh.",
                17, NSFontWeightLight);
            [list addArrangedSubview:none];
        }
        scroll.documentView = list;
        [body addArrangedSubview:scroll];
        [NSLayoutConstraint activateConstraints:@[
            [scroll.heightAnchor constraintEqualToConstant:222],
            [scroll.widthAnchor constraintEqualToAnchor:body.widthAnchor],
            [list.leadingAnchor constraintEqualToAnchor:scroll.contentView.leadingAnchor],
            [list.trailingAnchor constraintEqualToAnchor:scroll.contentView.trailingAnchor],
            [list.topAnchor constraintEqualToAnchor:scroll.contentView.topAnchor]
        ]];
        NSTextField *warning = DigitsInstallerMakeLabel(@"Binding to a display other than the digitizer’s own display has not been tested.",
            13, NSFontWeightLight);
        warning.textColor = NSColor.secondaryLabelColor;
        [body addArrangedSubview:warning];
        [warning.widthAnchor constraintEqualToAnchor:body.widthAnchor].active = YES;
    } else if (self.step == DigitsInstallerStepTouch) {
        NSTextField *approval = DigitsInstallerMakeLabel(
            @"If macOS asks, choose Open System Settings and allow Digits Touch.\n\nClicked OK instead? Open System Settings → General → Login Items & Extensions. At the bottom, find the Extensions categories → Driver Extensions → Digits.\n\nComplete the approval and return here. We’ll wait for macOS to accept it.",
            16, NSFontWeightLight);
        [body addArrangedSubview:approval];
        [approval.widthAnchor constraintEqualToAnchor:body.widthAnchor].active = YES;
    } else if (self.step == DigitsInstallerStepDriver) {
        NSTextField *approval = DigitsInstallerMakeLabel(
            @"If you missed the dialog, open System Settings → Privacy & Security → Security at the bottom → Allow.\n\nChoose Restart Later, then look for the separate cache authorization dialog and enter your password. Rebooting without completing that confirmation will not enable the driver.\n\nKeep this installer open. Confirm below, then choose Check Approval.",
            16, NSFontWeightLight);
        [body addArrangedSubview:approval];
        [approval.widthAnchor constraintEqualToAnchor:body.widthAnchor].active = YES;
        self.passwordConfirmation = [NSButton checkboxWithTitle:
            @"I completed the password confirmation after choosing Restart Later."
            target:self action:@selector(confirmPassword:)];
        self.passwordConfirmation.font = [NSFont systemFontOfSize:14 weight:NSFontWeightLight];
        self.passwordConfirmation.translatesAutoresizingMaskIntoConstraints = NO;
        self.passwordConfirmation.cell.wraps = YES;
        self.passwordConfirmation.state = self.passwordConfirmationReceived ? NSControlStateValueOn : NSControlStateValueOff;
        self.passwordConfirmation.enabled = !self.previewOnly;
        [body addArrangedSubview:self.passwordConfirmation];
        [self.passwordConfirmation.widthAnchor constraintEqualToAnchor:body.widthAnchor].active = YES;
        [self.passwordConfirmation.heightAnchor constraintGreaterThanOrEqualToConstant:38].active = YES;
        NSTextField *explanation = DigitsInstallerMakeLabel(
            @"Wait until the separate password confirmation has finished before continuing.",
            12, NSFontWeightLight);
        explanation.textColor = NSColor.secondaryLabelColor;
        [body addArrangedSubview:explanation];
        [explanation.widthAnchor constraintEqualToAnchor:body.widthAnchor].active = YES;
    } else if (self.step == DigitsInstallerStepFinished) {
        NSTextField *later = DigitsInstallerMakeLabel(@"You can restart now, or close this installer and restart when you’re ready.",
            16, NSFontWeightLight);
        [body addArrangedSubview:later];
        [later.widthAnchor constraintEqualToAnchor:body.widthAnchor].active = YES;
    }
    return content;
}
@end
