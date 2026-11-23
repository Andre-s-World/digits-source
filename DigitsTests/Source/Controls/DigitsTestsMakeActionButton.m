#import "DigitsTests.h"
NSButton *DigitsTestsMakeActionButton(NSString *title, NSString *symbol, id target, SEL action)
{
    // Match the main Digits actions without coupling the embedded Tester to its UI header.
    NSButton *button = [NSButton buttonWithTitle:title target:target action:action];
    button.font = [NSFont systemFontOfSize:16 weight:NSFontWeightLight];
    button.controlSize = NSControlSizeLarge;
    button.bezelStyle = NSBezelStyleRounded;
    button.image = [NSImage imageWithSystemSymbolName:symbol accessibilityDescription:title];
    button.imagePosition = NSImageLeading;
    button.imageScaling = NSImageScaleProportionallyDown;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button.heightAnchor constraintEqualToConstant:44].active = YES;
    [button.widthAnchor constraintGreaterThanOrEqualToConstant:110].active = YES;
    return button;
}
