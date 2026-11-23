#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (Progress)
- (void)setWorking:(BOOL)working message:(NSString *)message {
    self.busy = working;
    self.statusMessage = message ?: @"";
    [self updateControls];
}
@end
