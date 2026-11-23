#import "DigitsInstallerInternal.h"

@implementation DigitsInstallerBackend (PerformOperation)
- (void)performOperation:(NSString *)status worker:(NSDictionary *(^)(void))worker
             completion:(DigitsInstallerCompletion)completion {
    if (self.operationInProgress) {
        completion(NO, @"Another Digits operation is still running.");
        return;
    }
    self.operationInProgress = YES;
    if (self.statusUpdate)
        self.statusUpdate(status);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSDictionary *result = worker();
        dispatch_async(dispatch_get_main_queue(), ^{
            self.operationInProgress = NO;
            completion([result[@"success"] boolValue], result[@"message"] ?: @"The operation did not complete.");
        });
    });
}
@end
