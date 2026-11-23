#import "DigitsApplicationController.h"
#import <SystemExtensions/SystemExtensions.h>

@class DigitsTesterController;

NS_ASSUME_NONNULL_BEGIN

@interface DigitsApplicationOperations : NSObject <DigitsAppActions, OSSystemExtensionRequestDelegate>
@property(nonatomic, strong, nullable) DigitsTesterController *tester;
@property(nonatomic, copy, nullable) void (^statusUpdate)(NSString *message);
@property(nonatomic, copy, nullable) DigitsActionCompletion uninstallCompletion;
@property(nonatomic) BOOL maintenanceRunning;
@end

@interface DigitsApplicationOperations (Methods)
- (void)runMaintenanceAction:(NSString *)action argument:(NSString *)argument
                 completion:(DigitsActionCompletion)completion;
@end

FOUNDATION_EXPORT NSDictionary *_Nullable DigitsDecodeMaintenanceResult(NSString *_Nullable output);

NS_ASSUME_NONNULL_END
