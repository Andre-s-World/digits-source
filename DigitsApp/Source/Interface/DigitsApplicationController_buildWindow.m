#import "DigitsApplicationController.h"
#import <QuartzCore/QuartzCore.h>

@implementation DigitsApplicationController (Window)
- (void)buildWindow {
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 900, 600)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"Digits";
    self.window.titlebarAppearsTransparent = YES;
    self.window.releasedWhenClosed = NO;
    self.window.delegate = self;
    self.window.contentView = [[DigitsBackgroundView alloc] initWithFrame:self.window.contentView.bounds];
    self.rootView = self.window.contentView;
    self.rootView.wantsLayer = YES;
    self.rootView.layer.masksToBounds = YES;

    NSImageView *mark = [[NSImageView alloc] initWithFrame:NSZeroRect];
    mark.translatesAutoresizingMaskIntoConstraints = NO;
    mark.image = [[NSImage alloc] initWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"Digits" withExtension:@"icns"]];
    mark.imageScaling = NSImageScaleProportionallyUpOrDown;
    mark.accessibilityLabel = @"Digits, five colorful touch points";
    [self.rootView addSubview:mark];

    NSTextField *title = DigitsMakeLabel(@"Digits", 52, NSFontWeightUltraLight);
    NSTextField *subtitle = DigitsMakeLabel(@"A place for every touch.", 27, NSFontWeightLight);
    self.bindingLabel = DigitsMakeLabel(@"Native touch that works as it should", 17, NSFontWeightLight);
    self.bindingLabel.textColor = NSColor.secondaryLabelColor;
    self.statusLabel = DigitsMakeLabel(@"", 15, NSFontWeightLight);
    self.statusLabel.textColor = NSColor.secondaryLabelColor;
    self.operationSpinner = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
    self.operationSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    self.operationSpinner.style = NSProgressIndicatorStyleSpinning;
    self.operationSpinner.controlSize = NSControlSizeSmall;
    self.operationSpinner.indeterminate = YES;
    self.operationSpinner.displayedWhenStopped = NO;
    self.operationSpinner.hidden = YES;
    self.operationSpinner.accessibilityLabel = @"Digits operation in progress";
    self.approvalHelpLabel = DigitsMakeLabel(
        @"Keep Digits open. macOS may ask separately for your account password to update the startup cache.",
        13, NSFontWeightLight);
    self.approvalHelpLabel.textColor = NSColor.secondaryLabelColor;
    self.approvalHelpLabel.hidden = YES;
    self.footerLabel = DigitsMakeLabel(@"", 12, NSFontWeightLight);
    self.footerLabel.textColor = NSColor.tertiaryLabelColor;
    NSButton *rebind = DigitsMakeActionButton(@"Rebind Display", @"display", self, @selector(showDisplayPanel:));
    NSButton *tester = DigitsMakeActionButton(@"Tester", @"hand.draw", self, @selector(openTester:));
    self.testerButton = tester;
    tester.enabled = NO;
    NSButton *uninstall = DigitsMakeActionButton(@"Uninstall Digits", @"trash", self, @selector(uninstallDigits:));
    uninstall.contentTintColor = NSColor.secondaryLabelColor;
    self.actionButtons = @[rebind, tester, uninstall];
    NSStackView *primaryActions = [NSStackView stackViewWithViews:@[rebind, tester]];
    primaryActions.spacing = 12;
    primaryActions.translatesAutoresizingMaskIntoConstraints = NO;
    for (NSView *view in @[title, subtitle, self.bindingLabel, self.statusLabel,
                          self.operationSpinner, self.approvalHelpLabel, primaryActions,
                          uninstall, self.footerLabel])
        [self.rootView addSubview:view];
    [NSLayoutConstraint activateConstraints:@[
        [mark.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor constant:43],
        [mark.topAnchor constraintEqualToAnchor:self.rootView.topAnchor constant:35],
        [mark.widthAnchor constraintEqualToConstant:86], [mark.heightAnchor constraintEqualToConstant:86],
        [title.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor constant:48],
        [title.topAnchor constraintEqualToAnchor:mark.bottomAnchor constant:17],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:6],
        [self.bindingLabel.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.bindingLabel.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:28],
        [self.bindingLabel.widthAnchor constraintEqualToConstant:450],
        [primaryActions.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [primaryActions.topAnchor constraintEqualToAnchor:self.bindingLabel.bottomAnchor constant:28],
        [uninstall.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [uninstall.topAnchor constraintEqualToAnchor:primaryActions.bottomAnchor constant:12],
        [self.operationSpinner.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.operationSpinner.centerYAnchor constraintEqualToAnchor:self.statusLabel.firstBaselineAnchor constant:-5],
        [self.operationSpinner.widthAnchor constraintEqualToConstant:16],
        [self.operationSpinner.heightAnchor constraintEqualToConstant:16],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.operationSpinner.trailingAnchor constant:8],
        [self.statusLabel.topAnchor constraintEqualToAnchor:uninstall.bottomAnchor constant:16],
        [self.statusLabel.widthAnchor constraintEqualToConstant:450],
        [self.approvalHelpLabel.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.approvalHelpLabel.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:10],
        [self.approvalHelpLabel.widthAnchor constraintEqualToConstant:470],
        [self.footerLabel.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.footerLabel.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor constant:-23],
        [self.footerLabel.widthAnchor constraintEqualToConstant:790]
    ]];
    [self buildDisplayPanel];
    [self.window center];
    [self.window makeKeyAndOrderFront:nil];
}
@end
