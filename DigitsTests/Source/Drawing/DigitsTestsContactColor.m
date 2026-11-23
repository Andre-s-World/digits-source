#import "DigitsTests.h"
NSColor *DigitsTestsContactColor(NSUInteger identifier)
{
    const unsigned palette[] = { 0xBFDFFF, 0xFFC8B2, 0xC2F4D7, 0xD8C5FF, 0xFFE49F,
        0xB6EFF7, 0xFFBED9, 0xDDEDAF, 0xE9C8FF, 0xF8D8B8 };
    return DigitsTestsColor(palette[identifier % 10], 1);
}
