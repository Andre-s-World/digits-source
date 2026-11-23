#import "DigitsInstallerController.h"
NSButton *DigitsInstallerMakeActionButton(NSString *title, NSString *symbol, id target, SEL action) {
    NSButton *button = [NSButton buttonWithTitle:title target:target action:action];
    button.font = [NSFont systemFontOfSize:16 weight:NSFontWeightLight];
    button.controlSize = NSControlSizeLarge;
    button.bezelStyle = NSBezelStyleRounded;
    button.image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:nil];
    button.imagePosition = NSImageLeading;
    button.imageScaling = NSImageScaleProportionallyDown;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button.heightAnchor constraintEqualToConstant:44].active = YES;
    [button.widthAnchor constraintGreaterThanOrEqualToConstant:116].active = YES;
    return button;
}
