#import "DigitsTests.h"
@implementation DigitsTestsCanvas (Initialization)
- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.showTouches = YES;
    self.showCounters = YES;
    self.cardScale = 1;
    self.lastAction = @"Make it yours";
    self.identityNumbers = [NSMutableDictionary dictionary];
    self.activeContacts = [NSMutableDictionary dictionary];
    self.streamRows = [NSMutableArray array];
    self.lastNativeTimestamp = -1;
    self.tapCounts = [NSMutableArray arrayWithArray:@[@0,@0,@0,@0,@0,@0,@0,@0,@0,@0]];
    self.swipeCounts = [NSMutableArray arrayWithArray:@[@0,@0,@0,@0,@0]];
    self.allowedTouchTypes = NSTouchTypeMaskDirect;
    self.wantsRestingTouches = YES;
    NSPanGestureRecognizer *pan = [[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    pan.buttonMask = 0;
    pan.minimumNumberOfTouches = 1;
    pan.maximumNumberOfTouches = 1;
    [self configureRecognizer:pan];
    NSPanGestureRecognizer *multiPan = [[NSPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    multiPan.buttonMask = 0;
    multiPan.minimumNumberOfTouches = 2;
    multiPan.maximumNumberOfTouches = 10;
    [self configureRecognizer:multiPan];
    NSMagnificationGestureRecognizer *pinch = [[NSMagnificationGestureRecognizer alloc]
        initWithTarget:self action:@selector(pinch:)];
    [self configureRecognizer:pinch];
    NSRotationGestureRecognizer *turn = [[NSRotationGestureRecognizer alloc]
        initWithTarget:self action:@selector(turn:)];
    [self configureRecognizer:turn];
    // HID sessions count real one-to-ten-finger taps. A click recognizer here
    // would duplicate the same tap and cannot expose simultaneous touch counts.
    return self;
}
@end
