#import <AppKit/AppKit.h>
#import <IOKit/IOKitLib.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^DigitsActionCompletion)(BOOL success, NSString *message);

// Privileged changes belong to the one-shot operations backend, never to the views.
@protocol DigitsAppActions <NSObject>
@property(nonatomic, copy, nullable) void (^statusUpdate)(NSString *message);
- (void)applyDisplayUUID:(NSString *)displayUUID completion:(DigitsActionCompletion)completion;
- (void)uninstallDigitsWithCompletion:(DigitsActionCompletion)completion;
- (void)openTesterForDisplayUUID:(nullable NSString *)displayUUID
                    completion:(DigitsActionCompletion)completion;
@end

@interface DigitsDisplayOption : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *displayUUID;
@property(nonatomic, copy) NSString *detail;
@end

@interface DigitsApplicationController : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property(nonatomic, strong) id<DigitsAppActions> actions;
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) NSView *rootView;
@property(nonatomic, strong) NSVisualEffectView *displayPanel;
@property(nonatomic, strong) NSLayoutConstraint *displayPanelLeading;
@property(nonatomic, strong) NSStackView *displayList;
@property(nonatomic, strong) NSTextField *bindingLabel;
@property(nonatomic, strong) NSTextField *statusLabel;
@property(nonatomic, strong) NSProgressIndicator *operationSpinner;
@property(nonatomic, strong) NSTextField *approvalHelpLabel;
@property(nonatomic, strong) NSTextField *footerLabel;
@property(nonatomic, strong) NSTextField *panelStatusLabel;
@property(nonatomic, strong) NSButton *applyButton;
@property(nonatomic, strong) NSButton *testerButton;
@property(nonatomic, strong) NSArray<NSButton *> *actionButtons;
@property(nonatomic, strong) NSArray<DigitsDisplayOption *> *displayOptions;
@property(nonatomic, copy, nullable) NSString *savedDisplayUUID;
@property(nonatomic, copy, nullable) NSString *selectedDisplayUUID;
@property(nonatomic, copy, nullable) NSString *activeDisplayUUID;
@property(nonatomic) BOOL testerAvailable;
@property(nonatomic) BOOL bindingPendingRestart;
@property(nonatomic) BOOL displayPanelOpen;
@property(nonatomic) BOOL operationInProgress;
@property(nonatomic) IONotificationPortRef _Nullable statusNotificationPort;
@property(nonatomic, strong) NSMutableArray<NSNumber *> *statusNotificationIterators;
@property(nonatomic, strong, nullable) id screenChangeToken;
@property(nonatomic, strong, nullable) id workspaceWakeToken;
@property(nonatomic) BOOL statusObservationActive;
@property(nonatomic) BOOL statusRefreshScheduled;
@property(nonatomic) BOOL statusRefreshDeferred;
@end

@interface DigitsApplicationController (Methods)
- (instancetype)initWithActions:(id<DigitsAppActions>)actions;
- (void)buildWindow;
- (void)buildDisplayPanel;
- (void)refreshDisplayOptions;
- (void)refreshStatus;
- (void)startStatusObservation;
- (void)scheduleStatusRefresh;
- (void)stopStatusObservation;
- (void)showDisplayPanel:(id)sender;
- (void)closeDisplayPanel:(id)sender;
- (void)selectDisplay:(NSButton *)sender;
- (void)applyDisplaySelection:(id)sender;
- (void)openTester:(id)sender;
- (void)uninstallDigits:(id)sender;
- (void)setBusy:(BOOL)busy message:(NSString *)message;
- (void)presentResult:(BOOL)success title:(NSString *)title message:(NSString *)message;
@end

@interface DigitsBackgroundView : NSView
@end

FOUNDATION_EXPORT NSTextField *DigitsMakeLabel(NSString *text, CGFloat size, NSFontWeight weight);
FOUNDATION_EXPORT NSButton *DigitsMakeActionButton(NSString *title, NSString *symbol,
                                                  id target, SEL action);
FOUNDATION_EXPORT NSArray<DigitsDisplayOption *> *DigitsCopyDisplayOptions(void);
FOUNDATION_EXPORT NSString *_Nullable DigitsReadSavedDisplayUUID(void);
FOUNDATION_EXPORT NSDictionary *DigitsCopyServiceProperties(NSString *serviceClass,
                                                            NSDictionary *_Nullable propertyMatch);
FOUNDATION_EXPORT NSDictionary *DigitsCopyTouchRuntimeState(void);
FOUNDATION_EXPORT void DigitsStatusRegistryChanged(void *context, io_iterator_t iterator);

NS_ASSUME_NONNULL_END
