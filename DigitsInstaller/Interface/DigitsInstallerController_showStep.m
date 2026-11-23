#import "DigitsInstallerController.h"
#import <QuartzCore/QuartzCore.h>
@implementation DigitsInstallerController (Navigation)
- (void)showStep:(DigitsInstallerStep)step {
    self.step = step;
    self.transitionGeneration += 1;
    if (step == DigitsInstallerStepDisplay)
        [self refreshDisplayOptions];
    if (step == DigitsInstallerStepDriver) {
        self.driverInstalled = NO;
        self.driverLoadabilityConfirmed = NO;
        self.passwordConfirmationReceived = NO;
    }
    [self.rootView layoutSubtreeIfNeeded];
    NSView *previousView = self.stageView;
    NSView *nextView = [self makeStageContent];
    nextView.frame = self.contentContainer.bounds;
    nextView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    nextView.wantsLayer = YES;
    self.stageView = nextView;
    [self.contentContainer addSubview:nextView];
    BOOL animate = previousView && !NSWorkspace.sharedWorkspace.accessibilityDisplayShouldReduceMotion;
    if (animate) {
        nextView.alphaValue = 0;
        nextView.frame = NSOffsetRect(nextView.frame, 32, 0);
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.28;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            nextView.animator.alphaValue = 1;
            [nextView.animator setFrame:self.contentContainer.bounds];
            previousView.animator.alphaValue = 0;
            [previousView.animator setFrame:NSOffsetRect(previousView.frame, -24, 0)];
        } completionHandler:^{ [previousView removeFromSuperview]; }];
    } else {
        [previousView removeFromSuperview];
    }
    NSArray<NSColor *> *colors = @[NSColor.systemPurpleColor, NSColor.systemBlueColor,
        NSColor.systemTealColor, NSColor.systemPinkColor, NSColor.systemOrangeColor, NSColor.systemGreenColor];
    for (NSUInteger index = 0; index < self.stepLabels.count; index++) {
        BOOL current = index == (NSUInteger)step;
        BOOL completed = index < (NSUInteger)step;
        self.stepLabels[index].textColor = current ? NSColor.labelColor : NSColor.secondaryLabelColor;
        self.stepLabels[index].font = [NSFont systemFontOfSize:16 weight:current ? NSFontWeightRegular : NSFontWeightLight];
        self.stepMarkers[index].stringValue = completed ? @"✓" : [NSString stringWithFormat:@"%lu", index + 1];
        self.stepMarkers[index].textColor = current || completed ? colors[index] : NSColor.tertiaryLabelColor;
        self.stepMarkers[index].superview.layer.backgroundColor = [colors[index] colorWithAlphaComponent:current ? 0.20 : 0.07].CGColor;
    }
    [self updateControls];
}
@end
