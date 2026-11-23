#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (Configuration)
- (void)configureBackend:(DigitsInstallerBackend *)backend previewOnly:(BOOL)previewOnly {
    self.backend = backend;
    self.previewOnly = previewOnly;
    self.displayOptions = @[];
    self.statusMessage = @"Checking this installation…";
    __weak DigitsInstallerController *weakSelf = self;
    backend.statusUpdate = ^(NSString *message) {
        DigitsInstallerController *controller = weakSelf;
        if (controller) {
            controller.statusMessage = message ?: @"";
            controller.statusLabel.stringValue = controller.statusMessage;
        }
    };
}
@end
