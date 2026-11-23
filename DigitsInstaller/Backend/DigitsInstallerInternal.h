#import "DigitsInstallerBackend.h"
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

#define DIGITS_DRIVER_PACKAGE @"Digits Driver 0.2.4.pkg"
#define DIGITS_DRIVER_PACKAGE_SHA256 @"5c6a66c64c16ce2ecefcff7b17e8e44bd08c3fb54ab2528cbcc8a143effaaafb"
#define DIGITS_HOST_IDENTIFIER @"local.digits.touch.host"
#define DIGITS_DRIVER_IDENTIFIER @"local.digits.driver"
#define DIGITS_EXPECTED_KERNEL @"Darwin Kernel Version 27.3.0: Fri Oct 30 02:01:13 PDT 2026; root:xnu-13432.60.57~99/RELEASE_ARM64_T6050"

@interface DigitsInstallerBackend ()
@property(nonatomic) BOOL operationInProgress;
@property(nonatomic) BOOL touchActivationConfirmed;
@end
@interface DigitsInstallerBackend (Internal)
- (void)performOperation:(NSString *)status worker:(NSDictionary *(^)(void))worker
             completion:(DigitsInstallerCompletion)completion;
- (NSDictionary *)runMaintenanceAction:(NSString *)action argument:(nullable NSString *)argument;
- (void)runHostMode:(NSString *)mode completion:(DigitsInstallerCompletion)completion;
@end

FOUNDATION_EXPORT NSDictionary *DigitsInstallerRunTask(NSString *executable, NSArray<NSString *> *arguments);
FOUNDATION_EXPORT NSDictionary *DigitsInstallerResult(BOOL success, NSString *message);
FOUNDATION_EXPORT NSString *_Nullable DigitsInstallerFileSHA256(NSString *path);
FOUNDATION_EXPORT BOOL DigitsInstallerVerifyCode(NSString *path, NSString *identifier, NSError **error);
FOUNDATION_EXPORT NSDictionary *_Nullable DigitsInstallerVerifyPayloads(NSString *directory, NSError **error);
FOUNDATION_EXPORT NSDictionary *DigitsInstallerInspectInstallation(void);
FOUNDATION_EXPORT BOOL DigitsInstallerStopApplication(NSError **error);
FOUNDATION_EXPORT NSArray<NSString *> *DigitsInstallerSettingsPaths(void);
FOUNDATION_EXPORT NSDictionary *DigitsInstallerMaintenanceRun(NSArray<NSString *> *arguments);
FOUNDATION_EXPORT NSDictionary *DigitsInstallerMaintenanceInstallApp(NSString *uuid, BOOL reinstall,
                                                                      NSString *payloadDirectory);
FOUNDATION_EXPORT NSDictionary *DigitsInstallerMaintenanceInstallDriver(NSString *payloadDirectory);
FOUNDATION_EXPORT NSDictionary *DigitsInstallerMaintenanceCheckDriver(void);
FOUNDATION_EXPORT NSDictionary *DigitsInstallerMaintenanceUninstall(void);
FOUNDATION_EXPORT NSDictionary *DigitsInstallerMaintenanceRebuildStartupCache(void);
FOUNDATION_EXPORT NSDictionary *DigitsInstallerMaintenancePrepareRemovalHost(NSString *payloadDirectory);
FOUNDATION_EXPORT BOOL DigitsInstallerMaintenanceRemoveFiles(BOOL forgetReceipts, NSError **error);
FOUNDATION_EXPORT BOOL DigitsInstallerMaintenanceWriteBinding(NSString *uuid, NSError **error);
FOUNDATION_EXPORT BOOL DigitsInstallerMaintenanceValidateDestinations(NSError **error);

NS_ASSUME_NONNULL_END
