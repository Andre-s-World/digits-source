#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (LastWindow)
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)application {
    (void)application;
    return YES;
}
@end
