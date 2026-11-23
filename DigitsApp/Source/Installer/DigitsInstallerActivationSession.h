#import <AppKit/AppKit.h>
#import <SystemExtensions/SystemExtensions.h>

// A short-lived mode of the installed, entitled host. It owns only an explicit
// installer request; normal Digits launches never activate or replace a driver.
@interface DigitsInstallerActivationSession : NSObject <NSApplicationDelegate, OSSystemExtensionRequestDelegate>
@property(nonatomic) BOOL activation;
@property(nonatomic) int exitStatus;
@property(nonatomic) BOOL finished;
@property(nonatomic, strong) OSSystemExtensionRequest *request;
@end

@interface DigitsInstallerActivationSession (Operations)
- (instancetype)initWithActivation:(BOOL)activation;
- (void)emitEvent:(NSDictionary *)event;
- (void)finishWithEvent:(NSDictionary *)event status:(int)status;
@end

BOOL DigitsInstallerHostIsValid(NSString **message);
