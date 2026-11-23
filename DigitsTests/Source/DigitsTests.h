#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDKeys.h>

@class DigitsTestsReportObserver;
@class DigitsTestsTouchSession;
@class DigitsTestsSwitch;
NSDictionary *DigitsTestsRegistryProperties(io_registry_entry_t entry);
void DigitsTestsInputReportReceived(void *context, IOReturn result, void *sender,
    IOHIDReportType type, uint32_t reportID, uint8_t *report, CFIndex length);

NSColor *DigitsTestsColor(unsigned rgb, CGFloat alpha);
NSColor *DigitsTestsContactColor(NSUInteger identifier);
void DigitsTestsDrawText(NSString *text, NSRect rect, CGFloat size, NSColor *color, NSFontWeight weight);
NSString *DigitsTestsDisplayUUID(NSScreen *screen);
NSButton *DigitsTestsMakeActionButton(NSString *title, NSString *symbol, id target, SEL action);

@interface DigitsTestsCanvas : NSView <NSGestureRecognizerDelegate>
@property BOOL showTouches;
@property BOOL showCounters;
@property BOOL showStream;
@property CGFloat cardScale;
@property CGFloat cardRotation;
@property NSPoint cardShift;
@property CGFloat panStartX;
@property CGFloat panStartY;
@property NSPoint panBase;
@property CGFloat pinchBase;
@property CGFloat pinchStart;
@property CGFloat turnBase;
@property CGFloat turnStart;
@property NSUInteger dragUpdates;
@property NSUInteger panUpdates;
@property NSUInteger pinchUpdates;
@property NSUInteger rotationUpdates;
@property NSUInteger tapCount;
@property NSUInteger oneFingerDragCount;
@property NSUInteger twoFingerDragCount;
@property(strong) NSMutableArray<NSNumber *> *tapCounts;
@property(strong) NSMutableArray<NSNumber *> *swipeCounts;
@property(strong) DigitsTestsTouchSession *touchSession;
@property(strong) DigitsTestsTouchSession *pendingTouchSession;
@property NSUInteger sessionGeneration;
@property NSUInteger nativeFrameCount;
@property NSUInteger hidFrameCount;
@property uint16_t hidScanTime;
@property uint8_t hidContactCount;
@property(copy) NSString *reportObserverStatus;
@property NSUInteger nextContactIdentifier;
@property(copy) NSString *lastAction;
@property(strong) NSMutableDictionary *identityNumbers;
@property(strong) NSMutableDictionary<NSNumber *, NSDictionary *> *activeContacts;
@property(strong) NSMutableArray<NSDictionary *> *streamRows;
@property NSTimeInterval lastNativeTimestamp;
@property CGFloat bouncePosition;
@property CGFloat bounceVelocity;
@property CGFloat bounceEnergy;
@property CGFloat explosionProgress;
@property BOOL exploding;
@property NSTimeInterval lastAnimationTime;
@property(strong) NSTimer *animationTimer;
@end

@interface DigitsTestsCanvas (Operations)
- (BOOL)isDark;
- (CGFloat)sidebarWidth;
- (NSPoint)cardCenter;
- (BOOL)containsCardPoint:(NSPoint)point;
- (void)configureRecognizer:(NSGestureRecognizer *)recognizer;
- (void)consumeNativeEvent:(NSEvent *)event;
- (void)consumeNormalizedReport:(NSData *)report;
- (void)appendStream:(NSString *)text identifier:(NSUInteger)identifier;
- (void)observeContactSession:(NSDictionary<NSNumber *, NSDictionary *> *)contacts scanTime:(uint16_t)scanTime;
- (void)completeContactSession:(DigitsTestsTouchSession *)session;
- (void)markContactSessionConsumed:(BOOL)cardDrag;
- (void)pan:(NSPanGestureRecognizer *)recognizer;
- (void)pinch:(NSMagnificationGestureRecognizer *)recognizer;
- (void)turn:(NSRotationGestureRecognizer *)recognizer;
- (void)tap:(NSClickGestureRecognizer *)recognizer;
- (void)bounceCard;
- (void)animateFrame:(NSTimer *)timer;
- (void)resetCanvas;
- (void)drawBackground;
- (void)drawCard;
- (void)drawContacts;
- (void)drawSidebar;
@end

@interface DigitsTesterController : NSObject <NSWindowDelegate>
@property(strong) NSWindow *window;
@property(strong) DigitsTestsCanvas *canvas;
@property(strong) id eventMonitor;
@property(strong) DigitsTestsSwitch *touchesButton;
@property(strong) DigitsTestsSwitch *countersButton;
@property(strong) DigitsTestsSwitch *streamButton;
@property(copy) NSString *requestedDisplayUUID;
@property(strong) DigitsTestsReportObserver *reportObserver;
@property(strong) NSGlassEffectView *toolbarGlass;
@property(strong) NSStackView *toolbarControls;
@property(strong) id accessibilityObserver;
@end

@interface DigitsTestsReportObserver : NSObject
@property(assign) IOHIDDeviceRef device;
@property BOOL opened;
@property(strong) NSMutableData *reportBuffer;
@property(weak) DigitsTestsCanvas *canvas;
@end

@interface DigitsTestsReportObserver (Operations)
+ (NSDictionary *)preflightForDisplayUUID:(NSString *)uuid;
- (BOOL)startForDisplayUUID:(NSString *)uuid canvas:(DigitsTestsCanvas *)canvas error:(NSError **)error;
- (void)stop;
@end

@interface DigitsTesterController (Operations)
- (void)showForDisplayUUID:(NSString *)uuid;
- (NSScreen *)selectedScreen;
- (void)buildWindow;
- (void)layoutToolbar;
- (void)updateToolbarAccessibility;
- (void)toggleTouches:(DigitsTestsSwitch *)sender;
- (void)toggleCounters:(DigitsTestsSwitch *)sender;
- (void)toggleStream:(DigitsTestsSwitch *)sender;
- (void)reset:(id)sender;
- (void)closeTester:(id)sender;
- (void)saveSnapshot:(id)sender;
@end

// One session spans the first tip-down through the last tip-up. Coordinate maps
// retain released contacts so every member contributes to movement classification.
@interface DigitsTestsTouchSession : NSObject
@property NSTimeInterval startedAt;
@property NSTimeInterval endedAt;
@property NSTimeInterval lastContactAddedAt;
@property uint16_t firstScanTime;
@property uint16_t lastScanTime;
@property NSUInteger maximumCount;
@property CGFloat maximumTravel;
@property BOOL allContactsBeganOnCard;
@property BOOL anyContactBeganOnCard;
@property BOOL consumed;
@property BOOL cardDragRecognized;
@property BOOL cohortChanged;
@property BOOL classified;
@property(strong) NSMutableDictionary<NSNumber *, NSValue *> *origins;
@property(strong) NSMutableDictionary<NSNumber *, NSValue *> *latest;
@property(strong) NSMutableDictionary<NSNumber *, NSNumber *> *pathLengths;
@property(copy) NSSet<NSNumber *> *previousIdentifiers;
@end

// NSButton owns toggle state, keyboard tracking, disabled actions and accessibility.
// Only its appearance is custom: AppKit exposes no public per-NSSwitch tint API.
@interface DigitsTestsSwitch : NSButton
@property(strong) NSColor *accentColor;
@end

@interface DigitsTestsSwitch (Operations)
- (instancetype)initWithTitle:(NSString *)title accentColor:(NSColor *)accent target:(id)target action:(SEL)action;
@end
