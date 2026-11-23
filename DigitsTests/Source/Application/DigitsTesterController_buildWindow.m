#import "DigitsTests.h"
@implementation DigitsTesterController (BuildWindow)
- (void)buildWindow
{
    NSScreen *screen = [self selectedScreen];
    if (!screen) return;
    NSRect frame = screen.visibleFrame;
    if (frame.size.width < 800 || frame.size.height < 320) frame.size = NSMakeSize(1100, 430);
    self.window = [[NSWindow alloc] initWithContentRect:frame
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable |
                  NSWindowStyleMaskMiniaturizable
        backing:NSBackingStoreBuffered defer:NO screen:screen];
    self.window.title = @"Digits · Tester";
    self.window.delegate = self;
    self.window.releasedWhenClosed = NO;
    self.window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
    self.window.minSize = NSMakeSize(1050, 360);
    NSView *content = self.window.contentView;
    // The live canvas continues behind the floating native glass; there is no footer strip.
    self.canvas = [[DigitsTestsCanvas alloc] initWithFrame:content.bounds];
    self.canvas.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [content addSubview:self.canvas];
    NSButton *snapshot = DigitsTestsMakeActionButton(@"Snapshot…", @"camera", self, @selector(saveSnapshot:));
    NSButton *reset = DigitsTestsMakeActionButton(@"Reset", @"arrow.counterclockwise", self, @selector(reset:));
    NSButton *close = DigitsTestsMakeActionButton(@"Close", @"xmark", self, @selector(closeTester:));
    self.touchesButton = [[DigitsTestsSwitch alloc] initWithTitle:@"Show Touches"
        accentColor:DigitsTestsColor(0x78D4D5, 1) target:self action:@selector(toggleTouches:)];
    self.touchesButton.state = NSControlStateValueOn;
    self.countersButton = [[DigitsTestsSwitch alloc] initWithTitle:@"Counters"
        accentColor:DigitsTestsColor(0xB5A1E6, 1) target:self action:@selector(toggleCounters:)];
    self.countersButton.state = NSControlStateValueOn;
    self.streamButton = [[DigitsTestsSwitch alloc] initWithTitle:@"Touch Stream"
        accentColor:DigitsTestsColor(0xEDB48F, 1) target:self action:@selector(toggleStream:)];
    self.toolbarControls = [NSStackView stackViewWithViews:
        @[snapshot, reset, self.touchesButton, self.countersButton, self.streamButton, close]];
    self.toolbarControls.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    self.toolbarControls.alignment = NSLayoutAttributeCenterY;
    self.toolbarControls.spacing = 10;
    self.toolbarControls.distribution = NSStackViewDistributionFill;
    self.toolbarGlass = [[NSGlassEffectView alloc] initWithFrame:NSZeroRect];
    self.toolbarGlass.style = NSGlassEffectViewStyleRegular;
    self.toolbarGlass.cornerRadius = 32;
    NSView *glassContent = [[NSView alloc] initWithFrame:NSZeroRect];
    [glassContent addSubview:self.toolbarControls];
    self.toolbarGlass.contentView = glassContent;
    [content addSubview:self.toolbarGlass];
    __weak DigitsTesterController *weakSelf = self;
    self.accessibilityObserver = [NSWorkspace.sharedWorkspace.notificationCenter
        addObserverForName:NSWorkspaceAccessibilityDisplayOptionsDidChangeNotification object:nil
        queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *notification) {
            (void)notification;
            [weakSelf updateToolbarAccessibility];
        }];
    [self updateToolbarAccessibility];
    [self layoutToolbar];
    self.window.backgroundColor = NSColor.windowBackgroundColor;
    [self.window makeKeyAndOrderFront:nil];
    [self.window makeFirstResponder:self.canvas];
    [NSApp activateIgnoringOtherApps:YES];
    // Fullscreen is an ordinary AppKit presentation; no driver/service changes.
    dispatch_async(dispatch_get_main_queue(), ^{ [self.window toggleFullScreen:nil]; });
}
@end
