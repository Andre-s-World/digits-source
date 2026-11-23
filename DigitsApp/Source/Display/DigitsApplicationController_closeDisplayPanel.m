#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (CloseDisplays)
- (void)closeDisplayPanel:(id)sender {
    (void)sender;
    if (self.operationInProgress)
        return;
    self.displayPanelOpen = NO;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.24;
        context.allowsImplicitAnimation = YES;
        self.displayPanelLeading.constant = 0;
        [self.rootView layoutSubtreeIfNeeded];
    } completionHandler:nil];
}
@end
