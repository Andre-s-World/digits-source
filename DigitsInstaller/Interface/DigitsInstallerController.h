#import <AppKit/AppKit.h>
#import "../Backend/DigitsInstallerBackend.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DigitsInstallerStep) {
    DigitsInstallerStepIntroduction,
    DigitsInstallerStepDisplay,
    DigitsInstallerStepApplication,
    DigitsInstallerStepTouch,
    DigitsInstallerStepDriver,
    DigitsInstallerStepFinished
};

@interface DigitsInstallerDisplayOption : NSObject
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *displayUUID;
@property(nonatomic, copy) NSString *detail;
@end

@interface DigitsInstallerBackgroundView : NSView
@end

/// The interface owns navigation; the backend alone owns installation and authorization.
@interface DigitsInstallerController : NSObject <NSApplicationDelegate, NSWindowDelegate>
@property(nonatomic, strong, nullable) NSWindow *window;
@property(nonatomic, strong) DigitsInstallerBackend *backend;
@property(nonatomic) BOOL previewOnly;
@property(nonatomic) DigitsInstallerStep step;
@property(nonatomic, strong) NSView *rootView;
@property(nonatomic, strong) NSView *contentContainer;
@property(nonatomic, strong, nullable) NSView *stageView;
@property(nonatomic, strong) NSStackView *footerActions;
@property(nonatomic, strong) NSButton *primaryButton;
@property(nonatomic, strong) NSButton *secondaryButton;
@property(nonatomic, strong) NSButton *backButton;
@property(nonatomic, strong) NSTextField *statusLabel;
@property(nonatomic, strong) NSProgressIndicator *activityIndicator;
@property(nonatomic, strong) NSArray<NSTextField *> *stepLabels;
@property(nonatomic, strong) NSArray<NSTextField *> *stepMarkers;
@property(nonatomic, strong) NSArray<DigitsInstallerDisplayOption *> *displayOptions;
@property(nonatomic, copy, nullable) NSString *selectedDisplayUUID;
@property(nonatomic, strong, nullable) NSButton *passwordConfirmation;
@property(nonatomic, copy) NSString *statusMessage;
@property(nonatomic) BOOL busy;
@property(nonatomic) BOOL inspectionComplete;
@property(nonatomic) BOOL existingInstallation;
@property(nonatomic) BOOL driverInstalled;
@property(nonatomic) BOOL driverLoadabilityConfirmed;
@property(nonatomic) BOOL passwordConfirmationReceived;
@property(nonatomic) BOOL uninstallCompleted;
@property(nonatomic) NSUInteger transitionGeneration;
@end

@interface DigitsInstallerController (Interface)
- (instancetype)initWithBackend:(DigitsInstallerBackend *)backend previewOnly:(BOOL)previewOnly;
- (void)configureBackend:(DigitsInstallerBackend *)backend previewOnly:(BOOL)previewOnly;
- (void)buildWindow;
- (void)showStep:(DigitsInstallerStep)step;
- (NSView *)makeStageContent;
- (void)updateControls;
- (void)setWorking:(BOOL)working message:(NSString *)message;
- (void)inspectInstallation;
- (void)refreshDisplayOptions;
- (void)primaryAction:(id)sender;
- (void)secondaryAction:(id)sender;
- (void)backAction:(id)sender;
- (void)selectDisplay:(NSButton *)sender;
- (void)confirmPassword:(NSButton *)sender;
- (void)installApplication;
- (void)activateTouch;
- (void)installDriver;
- (void)checkDriverApproval;
- (void)advanceAfterConfirmedStep:(DigitsInstallerStep)step;
- (void)uninstallDigits;
- (void)restartComputer;
@end

NSTextField *DigitsInstallerMakeLabel(NSString *text, CGFloat size, NSFontWeight weight);
NSButton *DigitsInstallerMakeActionButton(NSString *title, NSString *symbol, id target, SEL action);
NSArray<DigitsInstallerDisplayOption *> *DigitsInstallerCopyDisplayOptions(void);

NS_ASSUME_NONNULL_END
