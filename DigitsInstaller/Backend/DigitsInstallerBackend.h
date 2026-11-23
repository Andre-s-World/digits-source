#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^DigitsInstallerCompletion)(BOOL success, NSString *message);

@interface DigitsInstallerBackend : NSObject
@property(nonatomic, copy, nullable) void (^statusUpdate)(NSString *message);
@property(nonatomic) BOOL reinstallRequested;
@end

@interface DigitsInstallerBackend (Operations)
- (void)inspectInstallationWithCompletion:(void (^)(NSDictionary *installation))completion;
- (void)installApplicationForDisplayUUID:(NSString *)uuid completion:(DigitsInstallerCompletion)completion;
- (void)activateTouchWithCompletion:(DigitsInstallerCompletion)completion;
- (void)installDriverWithCompletion:(DigitsInstallerCompletion)completion;
- (void)checkDriverApprovalWithCompletion:(DigitsInstallerCompletion)completion;
- (void)uninstallWithCompletion:(DigitsInstallerCompletion)completion;
@end

NS_ASSUME_NONNULL_END
