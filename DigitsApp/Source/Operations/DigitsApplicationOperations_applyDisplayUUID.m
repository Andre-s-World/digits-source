#import "DigitsApplicationOperations.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsApplicationOperations (ApplyDisplay)
- (void)applyDisplayUUID:(NSString *)displayUUID completion:(DigitsActionCompletion)completion {
    NSUUID *identifier = [[NSUUID alloc] initWithUUIDString:displayUUID];
    if (!identifier) {
        completion(NO, @"The selected display has no valid UUID.");
        return;
    }
    [self runMaintenanceAction:@"--apply-binding" argument:identifier.UUIDString completion:completion];
}
@end

#pragma clang diagnostic pop
