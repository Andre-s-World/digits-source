#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (Launch)
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    NSMenu *menuBar = [[NSMenu alloc] initWithTitle:@"Digits"];
    NSMenuItem *applicationItem = [[NSMenuItem alloc] initWithTitle:@"Digits" action:nil keyEquivalent:@""];
    NSMenu *applicationMenu = [[NSMenu alloc] initWithTitle:@"Digits"];
    [applicationMenu addItemWithTitle:@"About Digits" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [applicationMenu addItem:NSMenuItem.separatorItem];
    [applicationMenu addItemWithTitle:@"Quit Digits" action:@selector(terminate:) keyEquivalent:@"q"];
    applicationItem.submenu = applicationMenu;
    [menuBar addItem:applicationItem];
    NSApp.mainMenu = menuBar;
    [self buildWindow];
    [self refreshStatus];
    [self startStatusObservation];
    [NSApp activateIgnoringOtherApps:YES];
}
@end
