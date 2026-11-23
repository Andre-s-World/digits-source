#import "DigitsTests.h"
void DigitsTestsDrawText(NSString *text, NSRect rect, CGFloat size, NSColor *color, NSFontWeight weight)
{
    [text drawInRect:rect withAttributes:@{
        NSFontAttributeName: [NSFont systemFontOfSize:size weight:weight],
        NSForegroundColorAttributeName: color
    }];
}
