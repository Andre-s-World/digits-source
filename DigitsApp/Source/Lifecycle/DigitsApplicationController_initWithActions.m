#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (Initialize)
- (instancetype)initWithActions:(id<DigitsAppActions>)actions {
    self = [super init];
    if (self) {
        self.actions = actions;
        __weak DigitsApplicationController *weakController = self;
        actions.statusUpdate = ^(NSString *message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                DigitsApplicationController *controller = weakController;
                // Registry refreshes and late callbacks must not replace the
                // final result after an operation has already completed.
                if (!controller.operationInProgress)
                    return;
                controller.statusLabel.stringValue = message;
                if (controller.displayPanelOpen)
                    controller.panelStatusLabel.stringValue = message;
            });
        };
        self.displayOptions = @[];
        self.actionButtons = @[];
    }
    return self;
}
@end
