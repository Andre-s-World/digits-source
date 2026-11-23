#import "DigitsMaintenance.h"
#import <sys/stat.h>

NSString *DigitsMaintenanceCreateLogDirectory(NSError **error) {
    NSString *base = @"/Library/Logs/Digits";
    struct stat information;
    if (lstat(base.fileSystemRepresentation, &information) == 0 &&
        (!S_ISDIR(information.st_mode) || information.st_uid != 0 ||
         (information.st_mode & 0022) != 0)) {
        *error = DigitsMaintenanceError(@"The Digits log directory must be a protected system directory.");
        return nil;
    }
    NSString *directory = [base stringByAppendingPathComponent:
        [@"Maintenance-" stringByAppendingString:NSUUID.UUID.UUIDString]];
    if (![NSFileManager.defaultManager createDirectoryAtPath:directory
        withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0700} error:error])
        return nil;
    return directory;
}
