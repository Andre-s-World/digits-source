#import "DigitsTests.h"
@implementation DigitsTesterController (Snapshot)
- (void)saveSnapshot:(id)sender
{
    (void)sender;
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = @"Digits-Tester.png";
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        if (response != NSModalResponseOK || !panel.URL) return;
        NSBitmapImageRep *bitmap = [self.canvas bitmapImageRepForCachingDisplayInRect:self.canvas.bounds];
        [self.canvas cacheDisplayInRect:self.canvas.bounds toBitmapImageRep:bitmap];
        NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        NSError *error = nil;
        if (!png || ![png writeToURL:panel.URL options:NSDataWritingAtomic error:&error]) {
            NSAlert *alert = [NSAlert new];
            alert.messageText = @"Snapshot could not be saved";
            alert.informativeText = error.localizedDescription ?: @"The view could not be rendered.";
            [alert beginSheetModalForWindow:self.window completionHandler:nil];
        }
        [self.window makeFirstResponder:self.canvas];
    }];
}
@end
