#import "DigitsTests.h"
@implementation DigitsTestsCanvas (SidebarDrawing)
- (void)drawSidebar
{
    CGFloat width = [self sidebarWidth];
    if (width <= 0) return;
    BOOL dark = [self isDark];
    CGFloat left = self.bounds.size.width - width, height = self.bounds.size.height;
    NSColor *ink = DigitsTestsColor(dark ? 0xF5F4FF : 0x28314B, 1);
    NSColor *muted = DigitsTestsColor(dark ? 0xAEB8D2 : 0x697590, 1);
    [DigitsTestsColor(dark ? 0x121B31 : 0xFFFFFF, dark ? .8 : .68) setFill];
    NSRectFill(NSMakeRect(left, 0, width, height));
    DigitsTestsDrawText(self.showStream ? @"Touch stream" : @"In motion",
        NSMakeRect(left + 22, height - 56, width - 42, 34), 24, ink, NSFontWeightThin);
    NSString *live = self.hidFrameCount ? [NSString stringWithFormat:@"%lu contacts · %lu HID frames",
        (unsigned long)self.activeContacts.count, (unsigned long)self.hidFrameCount] :
        [NSString stringWithFormat:@"%lu contacts · %lu AppKit frames",
        (unsigned long)self.activeContacts.count, (unsigned long)self.nativeFrameCount];
    DigitsTestsDrawText(live, NSMakeRect(left + 23, height - 79, width - 45, 22), 13, muted, NSFontWeightLight);
    if (self.showStream) {
        DigitsTestsDrawText(self.reportObserverStatus ?: @"AppKit direct touches · pressure unavailable",
            NSMakeRect(left + 23, height - 103, width - 45, 22), 12, muted, NSFontWeightLight);
        if (!self.nativeFrameCount && !self.hidFrameCount) {
            DigitsTestsDrawText(@"Waiting for contact frames.\nGestures and contact reports are measured\nseparately. No input is generated here.",
                NSMakeRect(left + 23, height - 190, width - 42, 76), 14, muted, NSFontWeightLight);
        }
        CGFloat rowHeight = 25;
        NSUInteger limit = (NSUInteger)MAX(0, (height - 155) / rowHeight);
        for (NSUInteger i = 0; i < MIN(limit, self.streamRows.count); i++) {
            NSDictionary *row = self.streamRows[i];
            NSColor *color = DigitsTestsContactColor([row[@"identifier"] unsignedIntegerValue]);
            if (!dark) color = [color blendedColorWithFraction:.40 ofColor:DigitsTestsColor(0x24314A, 1)];
            NSString *text = row[@"text"];
            [text drawInRect:NSMakeRect(left + 22, height - 140 - i * rowHeight, width - 40, 23)
                withAttributes:@{ NSFontAttributeName:[NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightLight],
                    NSForegroundColorAttributeName:color }];
        }
        NSString *legend = self.hidFrameCount ? [NSString stringWithFormat:@"0D · 54 bytes · scan %u · count %u · T tip / C confidence",
            self.hidScanTime, self.hidContactCount] : @"C = app-local contact identity · x/y normalized";
        DigitsTestsDrawText(legend,
            NSMakeRect(left + 22, 16, width - 42, 20), 11, muted, NSFontWeightLight);
        return;
    }
    NSArray *labels = @[@"1-finger drag", @"2-finger drag", @"Pan", @"Zoom", @"Turn"];
    NSArray *values = @[@(self.oneFingerDragCount), @(self.twoFingerDragCount),
        @(self.panUpdates), @(self.pinchUpdates), @(self.rotationUpdates)];
    CGFloat rowHeight = MAX(18, MIN(27, (height - 224) / 5));
    // Keep the first row below the complete contact/frame line, including
    // a nine-point gap. Compress row spacing, not that independent header area.
    CGFloat cursor = height - 114;
    for (NSUInteger i = 0; i < labels.count; i++) {
        CGFloat y = cursor - i * rowHeight;
        NSColor *color = DigitsTestsContactColor(i + 2);
        if (!dark) color = [color blendedColorWithFraction:.35 ofColor:DigitsTestsColor(0x263149, 1)];
        DigitsTestsDrawText(labels[i], NSMakeRect(left + 22, y, width - 85, 23), rowHeight < 22 ? 15 : 17, ink, NSFontWeightLight);
        NSString *value = [values[i] stringValue];
        NSDictionary *attributes = @{NSFontAttributeName:[NSFont monospacedDigitSystemFontOfSize:rowHeight < 24 ? 20 : 23 weight:NSFontWeightThin],
            NSForegroundColorAttributeName:color};
        NSSize size = [value sizeWithAttributes:attributes];
        [value drawAtPoint:NSMakePoint(self.bounds.size.width - size.width - 22, y - 1) withAttributes:attributes];
    }
    cursor -= labels.count * rowHeight;
    CGFloat cellWidth = (width - 42) / 5;
    DigitsTestsDrawText(@"Taps · fingers", NSMakeRect(left + 22, cursor - 3, width - 42, 20), 13, muted, NSFontWeightLight);
    for (NSUInteger i = 0; i < 10; i++) {
        NSColor *color = DigitsTestsContactColor(i);
        if (!dark) color = [color blendedColorWithFraction:.35 ofColor:DigitsTestsColor(0x263149, 1)];
        NSString *value = [NSString stringWithFormat:@"%lu  %@", (unsigned long)i + 1, self.tapCounts[i]];
        DigitsTestsDrawText(value, NSMakeRect(left + 22 + (i % 5) * cellWidth,
            cursor - 27 - (i / 5) * 21, cellWidth, 21), 15, color, NSFontWeightLight);
    }
    DigitsTestsDrawText(@"Swipes · fingers", NSMakeRect(left + 22, cursor - 72, width - 42, 20), 13, muted, NSFontWeightLight);
    for (NSUInteger i = 0; i < 5; i++) {
        NSColor *color = DigitsTestsContactColor(i);
        if (!dark) color = [color blendedColorWithFraction:.35 ofColor:DigitsTestsColor(0x263149, 1)];
        NSString *value = [NSString stringWithFormat:@"%lu  %@", (unsigned long)i + 1, self.swipeCounts[i]];
        DigitsTestsDrawText(value, NSMakeRect(left + 22 + i * cellWidth, cursor - 95, cellWidth, 21),
            15, color, NSFontWeightLight);
    }
    if (cursor > 150) {
        NSString *transform = [NSString stringWithFormat:@"%.0f%%  ·  %.0f°", self.cardScale * 100, self.cardRotation * 180 / M_PI];
        DigitsTestsDrawText(transform, NSMakeRect(left + 22, 39, width - 44, 23), 15, ink, NSFontWeightLight);
        DigitsTestsDrawText(self.lastAction, NSMakeRect(left + 22, 15, width - 44, 22), 12, muted, NSFontWeightLight);
    }
}
@end
