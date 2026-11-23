#import "DigitsTests.h"
@implementation DigitsTestsCanvas (NormalizedReport)
- (void)consumeNormalizedReport:(NSData *)report
{
    if (report.length != 54 || !self.window.screen) return;
    const uint8_t *bytes = report.bytes;
    if (bytes[0] != 0x0d || bytes[53] > 10) return;
    NSMutableDictionary *contacts = [NSMutableDictionary dictionary];
    NSMutableArray *rows = [NSMutableArray array];
    uint16_t identifiers = 0;
    for (NSUInteger slot = 0; slot < 10; slot++) {
        NSUInteger offset = 1 + slot * 5;
        uint8_t flags = bytes[offset], identifier = flags >> 4;
        uint16_t x = bytes[offset + 1] | ((uint16_t)bytes[offset + 2] << 8);
        uint16_t y = bytes[offset + 3] | ((uint16_t)bytes[offset + 4] << 8);
        if ((flags & 0x0c) || x > 16383 || y > 9599) return;
        if (!(flags & 1)) continue;
        if (!(flags & 2) || (identifiers & (1U << identifier))) return;
        identifiers |= 1U << identifier;
        NSNumber *key = @(identifier);
        NSPoint normalized = NSMakePoint((CGFloat)x / 16383.0, (CGFloat)y / 9599.0);
        NSRect displayFrame = self.window.screen.frame;
        // HID Y starts at the panel's top edge; Cocoa screen coordinates start below.
        NSPoint global = NSMakePoint(displayFrame.origin.x + normalized.x * displayFrame.size.width,
            NSMaxY(displayFrame) - normalized.y * displayFrame.size.height);
        NSPoint local = [self convertPoint:[self.window convertPointFromScreen:global] fromView:nil];
        NSDictionary *previous = self.activeContacts[key];
        NSString *phase = previous ? (NSEqualPoints([previous[@"point"] pointValue], local) ? @"hold" : @"move") : @"begin";
        contacts[key] = @{ @"point":[NSValue valueWithPoint:local], @"normalized":[NSValue valueWithPoint:normalized], @"phase":phase };
        [rows addObject:@{ @"identifier":key, @"text":[NSString stringWithFormat:
            @"C%02u  %-5@ T1 C1  X%05u  Y%05u", identifier, phase, x, y] }];
    }
    if (contacts.count > bytes[53]) return;
    for (NSNumber *identifier in self.activeContacts) {
        if (!contacts[identifier]) [rows addObject:@{ @"identifier":identifier, @"text":
            [NSString stringWithFormat:@"C%02lu  end   T0 C0", (unsigned long)identifier.unsignedIntegerValue] }];
    }
    uint16_t scanTime = bytes[51] | ((uint16_t)bytes[52] << 8);
    [self observeContactSession:contacts scanTime:scanTime];
    self.activeContacts = contacts;
    self.hidFrameCount++;
    self.hidScanTime = scanTime;
    self.hidContactCount = bytes[53];
    for (NSDictionary *row in rows) [self appendStream:row[@"text"] identifier:[row[@"identifier"] unsignedIntegerValue]];
    [self setNeedsDisplay:YES];
}
@end
