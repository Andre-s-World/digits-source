#import "DigitsApplicationController.h"

@implementation DigitsApplicationController (RefreshDisplays)
- (void)refreshDisplayOptions {
    self.savedDisplayUUID = DigitsReadSavedDisplayUUID();
    self.displayOptions = DigitsCopyDisplayOptions();
    self.selectedDisplayUUID = self.savedDisplayUUID;
    for (NSView *view in self.displayList.arrangedSubviews) {
        [self.displayList removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    NSMutableArray<NSButton *> *rows = [NSMutableArray array];
    for (NSUInteger index = 0; index < self.displayOptions.count; index++) {
        DigitsDisplayOption *display = self.displayOptions[index];
        BOOL saved = [display.displayUUID isEqualToString:self.savedDisplayUUID];
        NSButton *row = [NSButton radioButtonWithTitle:@"" target:self action:@selector(selectDisplay:)];
        row.translatesAutoresizingMaskIntoConstraints = NO;
        row.tag = (NSInteger)index;
        row.state = saved ? NSControlStateValueOn : NSControlStateValueOff;
        NSString *name = saved ? [display.name stringByAppendingString:@"  ·  Saved"] : display.name;
        NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:[name stringByAppendingFormat:@"\n%@", display.detail] attributes:@{NSFontAttributeName:[NSFont systemFontOfSize:16 weight:NSFontWeightLight], NSForegroundColorAttributeName:NSColor.labelColor}];
        [title addAttributes:@{NSFontAttributeName:[NSFont systemFontOfSize:11 weight:NSFontWeightLight],NSForegroundColorAttributeName:NSColor.secondaryLabelColor} range:NSMakeRange(name.length + 1, display.detail.length)];
        row.attributedTitle = title;
        row.cell.wraps = YES;
        row.cell.lineBreakMode = NSLineBreakByWordWrapping;
        row.toolTip = display.name;
        [self.displayList addArrangedSubview:row];
        [row.widthAnchor constraintEqualToConstant:288].active = YES;
        [row.heightAnchor constraintGreaterThanOrEqualToConstant:72].active = YES;
        [rows addObject:row];
    }
    if (self.displayOptions.count == 0) {
        NSTextField *empty = DigitsMakeLabel(@"No displays are available right now.", 16, NSFontWeightLight);
        [self.displayList addArrangedSubview:empty];
    }
    self.applyButton.enabled = NO;
    self.panelStatusLabel.stringValue = @"A restart applies the new binding.";
}
@end
