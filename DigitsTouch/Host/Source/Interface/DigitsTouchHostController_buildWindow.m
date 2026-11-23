#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (Window)
- (void)buildWindow {
    self.window =
        [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 590, 300)
                                    styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                                              NSWindowStyleMaskMiniaturizable
                                      backing:NSBackingStoreBuffered
                                        defer:NO];
    self.window.title = @"Digits";
    self.window.releasedWhenClosed = NO;
    [self.window center];
    NSStackView *layout = [[NSStackView alloc] init];
    layout.orientation = NSUserInterfaceLayoutOrientationVertical;
    layout.alignment = NSLayoutAttributeLeading;
    layout.spacing = 18;
    layout.translatesAutoresizingMaskIntoConstraints = NO;
    [self.window.contentView addSubview:layout];
    [NSLayoutConstraint activateConstraints:@[
        [layout.leadingAnchor constraintEqualToAnchor:self.window.contentView.leadingAnchor
                                             constant:28],
        [layout.trailingAnchor constraintEqualToAnchor:self.window.contentView.trailingAnchor
                                              constant:-28],
        [layout.topAnchor constraintEqualToAnchor:self.window.contentView.topAnchor constant:28]
    ]];
    NSTextField *title = [NSTextField labelWithString:@"A place for every touch."];
    title.font = [NSFont systemFontOfSize:28 weight:NSFontWeightLight];
    [layout addArrangedSubview:title];
    self.statusLabel = [NSTextField wrappingLabelWithString:@""];
    self.statusLabel.font = [NSFont systemFontOfSize:15 weight:NSFontWeightLight];
    self.statusLabel.maximumNumberOfLines = 6;
    [layout addArrangedSubview:self.statusLabel];
    [self.statusLabel.widthAnchor constraintEqualToAnchor:layout.widthAnchor].active = YES;
    NSStackView *buttons = [[NSStackView alloc] init];
    buttons.spacing = 12;
    self.activateButton = [NSButton buttonWithTitle:@"Enable Touch"
                                             target:self
                                             action:@selector(activateTouch:)];
    self.deactivateButton = [NSButton buttonWithTitle:@"Uninstall Digits Touch"
                                               target:self
                                               action:@selector(deactivateTouch:)];
    [buttons addArrangedSubview:self.activateButton];
    [buttons addArrangedSubview:self.deactivateButton];
    [layout addArrangedSubview:buttons];
    NSTextField *version = [NSTextField labelWithString:@"Digits 0.1.6 · development build"];
    version.font = [NSFont systemFontOfSize:11 weight:NSFontWeightLight];
    version.textColor = NSColor.secondaryLabelColor;
    [layout addArrangedSubview:version];
    [self.window makeKeyAndOrderFront:nil];
}
@end
