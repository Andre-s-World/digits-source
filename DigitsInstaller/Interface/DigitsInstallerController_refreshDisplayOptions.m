#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (DisplayDiscovery)
- (void)refreshDisplayOptions {
    self.displayOptions = DigitsInstallerCopyDisplayOptions();
    BOOL selectedDisplayConnected = NO;
    for (DigitsInstallerDisplayOption *option in self.displayOptions) {
        if ([option.displayUUID isEqualToString:self.selectedDisplayUUID])
            selectedDisplayConnected = YES;
    }
    if (!selectedDisplayConnected)
        self.selectedDisplayUUID = nil;
}
@end
