#import "DigitsInstallerController.h"
#import <QuartzCore/QuartzCore.h>
@implementation DigitsInstallerController (Window)
- (void)buildWindow {
    if (self.window) {
        [self.window makeKeyAndOrderFront:nil];
        return;
    }
    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1030, 720)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
        backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"Digits Installer";
    self.window.titlebarAppearsTransparent = YES;
    self.window.releasedWhenClosed = NO;
    self.window.delegate = self;
    self.rootView = [[DigitsInstallerBackgroundView alloc] initWithFrame:self.window.contentView.bounds];
    self.window.contentView = self.rootView;
    self.rootView.wantsLayer = YES;
    self.rootView.layer.masksToBounds = YES;

    NSTextField *heading = DigitsInstallerMakeLabel(@"Digits", 45, NSFontWeightUltraLight);
    NSTextField *subheading = DigitsInstallerMakeLabel(@"A place for every touch.", 17, NSFontWeightLight);
    subheading.textColor = NSColor.secondaryLabelColor;
    [self.rootView addSubview:heading];
    [self.rootView addSubview:subheading];

    NSArray<NSString *> *names = @[@"Before we begin", @"Your display", @"Digits app",
        @"Digits Touch", @"Digits Driver", @"Ready to touch"];
    NSMutableArray *markers = [NSMutableArray array];
    NSMutableArray *labels = [NSMutableArray array];
    NSStackView *stepper = [NSStackView stackViewWithViews:@[]];
    stepper.orientation = NSUserInterfaceLayoutOrientationVertical;
    stepper.alignment = NSLayoutAttributeLeading;
    stepper.spacing = 16;
    stepper.translatesAutoresizingMaskIntoConstraints = NO;
    for (NSUInteger index = 0; index < names.count; index++) {
        // A plain square view has no text-field alignment insets. Keep its
        // circle independent of the label's line height and baseline metrics.
        NSView *badge = [NSView new];
        badge.translatesAutoresizingMaskIntoConstraints = NO;
        badge.wantsLayer = YES;
        badge.layer.cornerRadius = 14;
        badge.layer.masksToBounds = YES;
        NSTextField *marker = [NSTextField labelWithString:[NSString stringWithFormat:@"%lu", index + 1]];
        marker.font = [NSFont monospacedDigitSystemFontOfSize:14 weight:NSFontWeightRegular];
        marker.alignment = NSTextAlignmentCenter;
        marker.translatesAutoresizingMaskIntoConstraints = NO;
        [badge addSubview:marker];
        [NSLayoutConstraint activateConstraints:@[
            [badge.widthAnchor constraintEqualToConstant:28],
            [badge.heightAnchor constraintEqualToConstant:28],
            [marker.centerXAnchor constraintEqualToAnchor:badge.centerXAnchor],
            [marker.centerYAnchor constraintEqualToAnchor:badge.centerYAnchor]
        ]];
        NSTextField *label = DigitsInstallerMakeLabel(names[index], 16, NSFontWeightLight);
        NSStackView *row = [NSStackView stackViewWithViews:@[badge, label]];
        row.spacing = 12;
        row.alignment = NSLayoutAttributeCenterY;
        [row.heightAnchor constraintEqualToConstant:38].active = YES;
        [stepper addArrangedSubview:row];
        [markers addObject:marker];
        [labels addObject:label];
    }
    self.stepLabels = labels;
    self.stepMarkers = markers;
    [self.rootView addSubview:stepper];

    self.contentContainer = [NSView new];
    self.contentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentContainer.wantsLayer = YES;
    self.contentContainer.layer.masksToBounds = YES;
    [self.rootView addSubview:self.contentContainer];

    self.statusLabel = DigitsInstallerMakeLabel(@"", 14, NSFontWeightLight);
    self.statusLabel.textColor = NSColor.secondaryLabelColor;
    self.activityIndicator = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
    self.activityIndicator.style = NSProgressIndicatorStyleSpinning;
    self.activityIndicator.controlSize = NSControlSizeSmall;
    self.activityIndicator.displayedWhenStopped = NO;
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.rootView addSubview:self.statusLabel];
    [self.rootView addSubview:self.activityIndicator];

    NSGlassEffectView *footer = [[NSGlassEffectView alloc] initWithFrame:NSZeroRect];
    footer.translatesAutoresizingMaskIntoConstraints = NO;
    footer.cornerRadius = 30;
    footer.style = NSGlassEffectViewStyleRegular;
    footer.effectIsInteractive = !NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    NSView *footerContent = [NSView new];
    footer.contentView = footerContent;
    [self.rootView addSubview:footer];
    self.backButton = DigitsInstallerMakeActionButton(@"Back", @"chevron.left", self, @selector(backAction:));
    self.secondaryButton = DigitsInstallerMakeActionButton(@"Uninstall", @"trash", self, @selector(secondaryAction:));
    self.primaryButton = DigitsInstallerMakeActionButton(@"Next", @"arrow.right", self, @selector(primaryAction:));
    self.primaryButton.keyEquivalent = @"\r";
    self.footerActions = [NSStackView stackViewWithViews:@[self.backButton, self.secondaryButton, self.primaryButton]];
    self.footerActions.translatesAutoresizingMaskIntoConstraints = NO;
    self.footerActions.spacing = 10;
    [footerContent addSubview:self.footerActions];
    [NSLayoutConstraint activateConstraints:@[
        [heading.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor constant:34],
        [heading.topAnchor constraintEqualToAnchor:self.rootView.topAnchor constant:28],
        [subheading.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [subheading.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:1],
        [stepper.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
        [stepper.topAnchor constraintEqualToAnchor:subheading.bottomAnchor constant:48],
        [stepper.widthAnchor constraintEqualToConstant:205],
        [self.contentContainer.leadingAnchor constraintEqualToAnchor:self.rootView.leadingAnchor constant:278],
        [self.contentContainer.trailingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor constant:-36],
        [self.contentContainer.topAnchor constraintEqualToAnchor:self.rootView.topAnchor constant:70],
        [self.contentContainer.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor constant:-164],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor constant:26],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:footer.topAnchor constant:-17],
        [self.activityIndicator.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.statusLabel.centerYAnchor],
        [self.activityIndicator.widthAnchor constraintEqualToConstant:16],
        [self.activityIndicator.heightAnchor constraintEqualToConstant:16],
        [footer.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
        [footer.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor],
        [footer.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor constant:-27],
        [footer.heightAnchor constraintEqualToConstant:68],
        [self.footerActions.trailingAnchor constraintEqualToAnchor:footerContent.trailingAnchor constant:-12],
        [self.footerActions.centerYAnchor constraintEqualToAnchor:footerContent.centerYAnchor]
    ]];
    if (self.previewOnly) {
        NSTextField *preview = DigitsInstallerMakeLabel(@"Preview — nothing will be installed", 12, NSFontWeightMedium);
        preview.textColor = NSColor.systemOrangeColor;
        [self.rootView addSubview:preview];
        [NSLayoutConstraint activateConstraints:@[
            [preview.leadingAnchor constraintEqualToAnchor:heading.leadingAnchor],
            [preview.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor constant:-35],
            [preview.widthAnchor constraintEqualToConstant:220]
        ]];
    }
    [self.window center];
    [self showStep:DigitsInstallerStepIntroduction];
    [self.window makeKeyAndOrderFront:nil];
}
@end
