#import "DigitsTests.h"
@implementation DigitsTestsSwitch (Drawing)
- (void)drawRect:(NSRect)dirtyRect
{
    (void)dirtyRect;
    BOOL dark = [[self.effectiveAppearance bestMatchFromAppearancesWithNames:
        @[NSAppearanceNameDarkAqua, NSAppearanceNameAqua]] isEqual:NSAppearanceNameDarkAqua];
    BOOL contrast = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;
    BOOL on = self.state == NSControlStateValueOn;
    NSColor *accent = self.accentColor ?: NSColor.controlAccentColor;
    NSColor *base = NSColor.controlBackgroundColor;
    NSColor *trackColor = on ? accent : [accent blendedColorWithFraction:.78 ofColor:base];
    if (self.highlighted) trackColor = [trackColor blendedColorWithFraction:.12 ofColor:NSColor.blackColor];
    if (!self.enabled) trackColor = [trackColor blendedColorWithFraction:.70 ofColor:base];
    CGFloat centerY = NSMidY(self.bounds);
    NSRect trackRect = NSMakeRect(2, centerY - 13, 42, 26);
    NSBezierPath *track = [NSBezierPath bezierPathWithRoundedRect:trackRect xRadius:13 yRadius:13];
    [trackColor setFill]; [track fill];
    NSColor *outline = contrast ? NSColor.labelColor :
        [accent blendedColorWithFraction:.40 ofColor:dark ? NSColor.whiteColor : NSColor.blackColor];
    if (!self.enabled) outline = NSColor.disabledControlTextColor;
    [outline setStroke]; track.lineWidth = contrast ? 2 : 1; [track stroke];
    // An immediate thumb change also honors Reduce Motion without a second animator.
    CGFloat thumbX = on ? NSMaxX(trackRect) - 24 : NSMinX(trackRect) + 2;
    NSBezierPath *thumb = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(thumbX, centerY - 11, 22, 22)];
    [(self.enabled ? NSColor.whiteColor : NSColor.controlColor) setFill]; [thumb fill];
    [outline setStroke]; thumb.lineWidth = contrast ? 1.5 : .5; [thumb stroke];
    NSColor *labelColor = self.enabled ? [accent blendedColorWithFraction:dark ? .10 : .35
        ofColor:dark ? NSColor.whiteColor : NSColor.blackColor] : NSColor.disabledControlTextColor;
    NSFont *font = contrast ? [NSFont systemFontOfSize:15 weight:NSFontWeightRegular] : self.font;
    [self.title drawInRect:NSMakeRect(53, centerY - 10, MAX(0, self.bounds.size.width - 53), 22)
        withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:labelColor}];
    if (self.window.firstResponder == self && self.enabled) {
        NSBezierPath *focus = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 1, 3)
            xRadius:16 yRadius:16];
        [NSColor.keyboardFocusIndicatorColor setStroke]; focus.lineWidth = 2; [focus stroke];
    }
}
@end
