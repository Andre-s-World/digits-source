#import "DigitsTests.h"
NSColor *DigitsTestsColor(unsigned rgb, CGFloat alpha)
{
    return [NSColor colorWithSRGBRed:((rgb >> 16) & 255) / 255.0
                             green:((rgb >> 8) & 255) / 255.0
                              blue:(rgb & 255) / 255.0 alpha:alpha];
}
