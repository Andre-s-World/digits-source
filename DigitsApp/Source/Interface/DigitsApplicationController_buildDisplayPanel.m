#import "DigitsApplicationController.h"
#import <QuartzCore/QuartzCore.h>

@implementation DigitsApplicationController (DisplayPanel)
- (void)buildDisplayPanel {
    self.displayPanel = [[NSVisualEffectView alloc] initWithFrame:NSZeroRect];
    self.displayPanel.translatesAutoresizingMaskIntoConstraints = NO;
    self.displayPanel.material = NSVisualEffectMaterialSidebar;
    self.displayPanel.blendingMode = NSVisualEffectBlendingModeWithinWindow;
    self.displayPanel.state = NSVisualEffectStateActive;
    self.displayPanel.wantsLayer = YES;
    self.displayPanel.layer.cornerRadius = 20;
    self.displayPanel.layer.masksToBounds = YES;
    [self.rootView addSubview:self.displayPanel];
    self.displayPanelLeading = [self.displayPanel.leadingAnchor constraintEqualToAnchor:self.rootView.trailingAnchor constant:0];
    [NSLayoutConstraint activateConstraints:@[
        self.displayPanelLeading,
        [self.displayPanel.widthAnchor constraintEqualToConstant:346],
        [self.displayPanel.topAnchor constraintEqualToAnchor:self.rootView.topAnchor constant:17],
        [self.displayPanel.bottomAnchor constraintEqualToAnchor:self.rootView.bottomAnchor constant:-17]
    ]];
    NSTextField *title = DigitsMakeLabel(@"Your touch,\nyour display.", 29, NSFontWeightUltraLight);
    NSButton *close = [NSButton buttonWithImage:[NSImage imageWithSystemSymbolName:@"xmark.circle.fill" accessibilityDescription:@"Close display selection"] target:self action:@selector(closeDisplayPanel:)];
    close.bordered = NO;
    close.contentTintColor = NSColor.tertiaryLabelColor;
    close.translatesAutoresizingMaskIntoConstraints = NO;
    self.displayList = [[NSStackView alloc] initWithFrame:NSZeroRect];
    self.displayList.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.displayList.alignment = NSLayoutAttributeLeading;
    self.displayList.spacing = 10;
    self.displayList.translatesAutoresizingMaskIntoConstraints = NO;
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.drawsBackground = NO;
    scroll.hasVerticalScroller = YES;
    scroll.documentView = self.displayList;
    NSTextField *warning = DigitsMakeLabel(@"Binding to a display other than the digitizer’s own display has not been tested.", 13, NSFontWeightLight);
    warning.textColor = NSColor.secondaryLabelColor;
    self.panelStatusLabel = DigitsMakeLabel(@"A restart applies the new binding.", 13, NSFontWeightLight);
    self.panelStatusLabel.textColor = NSColor.secondaryLabelColor;
    self.applyButton = DigitsMakeActionButton(@"Use This Display", @"checkmark", self, @selector(applyDisplaySelection:));
    self.applyButton.keyEquivalent = @"\r";
    for (NSView *view in @[title, close, scroll, warning, self.panelStatusLabel, self.applyButton])
        [self.displayPanel addSubview:view];
    [NSLayoutConstraint activateConstraints:@[
        [title.leadingAnchor constraintEqualToAnchor:self.displayPanel.leadingAnchor constant:23],
        [title.topAnchor constraintEqualToAnchor:self.displayPanel.topAnchor constant:28],
        [title.widthAnchor constraintEqualToConstant:264],
        [close.trailingAnchor constraintEqualToAnchor:self.displayPanel.trailingAnchor constant:-14],
        [close.topAnchor constraintEqualToAnchor:self.displayPanel.topAnchor constant:14],
        [close.widthAnchor constraintEqualToConstant:22], [close.heightAnchor constraintEqualToConstant:22],
        [scroll.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.displayPanel.trailingAnchor constant:-23],
        [scroll.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:24],
        [scroll.bottomAnchor constraintEqualToAnchor:warning.topAnchor constant:-19],
        [self.displayList.leadingAnchor constraintEqualToAnchor:scroll.contentView.leadingAnchor],
        [self.displayList.trailingAnchor constraintEqualToAnchor:scroll.contentView.trailingAnchor],
        [self.displayList.topAnchor constraintEqualToAnchor:scroll.contentView.topAnchor],
        [warning.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [warning.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor],
        [warning.bottomAnchor constraintEqualToAnchor:self.panelStatusLabel.topAnchor constant:-12],
        [self.panelStatusLabel.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.panelStatusLabel.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor],
        [self.panelStatusLabel.bottomAnchor constraintEqualToAnchor:self.applyButton.topAnchor constant:-18],
        [self.applyButton.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [self.applyButton.trailingAnchor constraintEqualToAnchor:scroll.trailingAnchor],
        [self.applyButton.bottomAnchor constraintEqualToAnchor:self.displayPanel.bottomAnchor constant:-24]
    ]];
}
@end
