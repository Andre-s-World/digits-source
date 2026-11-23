#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (ShowDisplays)
- (void)showDisplayPanel:(id)sender {
    (void)sender;
    if (self.operationInProgress)
        return;
    [self refreshDisplayOptions];
    self.displayPanelOpen = YES;
    [self.rootView layoutSubtreeIfNeeded];
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.28;
        context.allowsImplicitAnimation = YES;
        self.displayPanelLeading.constant = -363;
        [self.rootView layoutSubtreeIfNeeded];
    } completionHandler:nil];
}
@end
