#import "DigitsTests.h"
int main(int argc, const char *argv[])
{
    @autoreleasepool {
        [NSApplication sharedApplication];
        DigitsTestsCanvas *view = [[DigitsTestsCanvas alloc] initWithFrame:NSMakeRect(0,0,1440,480)];
        view.appearance = [NSAppearance appearanceNamed:(argc > 2 ? NSAppearanceNameAqua : NSAppearanceNameDarkAqua)];
        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:1440 pixelsHigh:480 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
        NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
        [NSGraphicsContext saveGraphicsState];
        [NSGraphicsContext setCurrentContext:context];
        [view.effectiveAppearance performAsCurrentDrawingAppearance:^{
            [view displayRectIgnoringOpacity:view.bounds inContext:context];
        }];
        [NSGraphicsContext restoreGraphicsState];
        NSData *png = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        return [png writeToFile:[NSString stringWithUTF8String:argv[1]] atomically:YES] ? 0 : 1;
    }
}
