#import "DigitsTouchDisplayIdentity.h"
#import "DigitsTouchProtocol.h"
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <IOKit/IOKitLib.h>
#import <SystemExtensions/SystemExtensions.h>
#import <ServiceManagement/ServiceManagement.h>

@interface DigitsTouchHostController
    : NSObject <NSApplicationDelegate, OSSystemExtensionRequestDelegate>
@property(nonatomic) BOOL associationOnly;
@property(nonatomic) BOOL systemAssociation;
@property(nonatomic) BOOL refreshScheduled;
@property(nonatomic) BOOL monitoring;
@property(nonatomic) BOOL displayCallbackRegistered;
@property(nonatomic) BOOL signedForActivation;
@property(nonatomic) BOOL activationRequested;
@property(nonatomic) BOOL extensionRequestPending;
@property(nonatomic) BOOL shuttingDown;
@property(nonatomic, strong) dispatch_source_t bindingWatcher;
@property(nonatomic) IONotificationPortRef notificationPort;
@property(nonatomic) io_iterator_t arrivalIterator;
@property(nonatomic) io_iterator_t terminationIterator;
@property(nonatomic, copy) NSArray<NSNumber *> *displayEventIterators;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *displayInterests;
@property(nonatomic) io_connect_t driverConnection;
@property(nonatomic) uint64_t connectedTransportRegistryID;
@property(nonatomic) uint64_t connectedPhysicalUSBRegistryID;
@property(nonatomic, copy) NSString *activeBindingIdentity;
@property(nonatomic, copy) NSString *associationState;
@property(nonatomic, copy) NSString *activationState;
@property(nonatomic, copy) NSString *automaticAssociationState;
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) NSTextField *statusLabel;
@property(nonatomic, strong) NSButton *activateButton;
@property(nonatomic, strong) NSButton *deactivateButton;
@end

@interface DigitsTouchHostController (Operations)
- (void)buildWindow;
- (BOOL)hasActivationSignature;
- (void)activateTouch:(id)sender;
- (void)deactivateTouch:(id)sender;
- (void)startAssociation;
- (void)stopAssociation;
- (void)scheduleAssociationRefresh;
- (void)refreshAssociation;
- (NSDictionary *)loadDigitsDisplayBinding;
- (NSArray<NSDictionary *> *)copyTransportIdentities;
- (NSArray<DigitsTouchDisplayIdentity *> *)copyPhysicalDisplays;
- (DigitsTouchDisplayIdentity *)currentDisplayForIdentity:(DigitsTouchDisplayIdentity *)identity;
- (BOOL)connectTransport:(NSDictionary *)transport;
- (void)disconnectTransport;
- (void)bindDisplay:(DigitsTouchDisplayIdentity *)display;
- (void)updateStatus;
- (void)refreshAutomaticBindingState;
- (BOOL)disableAutomaticAssociation;
- (void)startBindingWatcher;
- (void)stopBindingWatcher;
- (void)pauseAssociation;
- (void)associationChanged:(NSNotification *)notification;
- (void)watchPhysicalDisplay:(io_service_t)service;
@end

CFMutableDictionaryRef DigitsTouchCreateTransportMatchingDictionary(void);
void DigitsTouchServicesChanged(void *context, io_iterator_t iterator);
void DigitsTouchDisplayChanged(CGDirectDisplayID display, CGDisplayChangeSummaryFlags flags,
                               void *context);
void DigitsTouchDisplayServiceChanged(void *context, io_service_t service,
                                     natural_t messageType, void *messageArgument);
int DigitsTouchConnectPhysicalDevice(void);
