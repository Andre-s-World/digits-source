#import "DigitsMaintenance.h"

BOOL DigitsMaintenancePrepareBinding(NSString *displayUUID, NSString *directory, NSError **error) {
    NSDictionary *binding = DigitsMaintenanceCreateBinding(displayUUID, error);
    if (!binding)
        return NO;
    if ([NSFileManager.defaultManager fileExistsAtPath:directory]) {
        *error = DigitsMaintenanceError(@"Preparation requires a new directory; existing results were preserved.");
        return NO;
    }
    if (![NSFileManager.defaultManager createDirectoryAtPath:directory
        withIntermediateDirectories:NO attributes:@{NSFilePosixPermissions:@0700} error:error])
        return NO;
    return DigitsMaintenanceWritePropertyList(binding,
        [directory stringByAppendingPathComponent:@"DigitsDisplayBinding.plist"], error);
}
