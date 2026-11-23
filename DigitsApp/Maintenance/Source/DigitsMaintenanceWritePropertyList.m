#import "DigitsMaintenance.h"
#import <sys/stat.h>
#import <unistd.h>

BOOL DigitsMaintenanceWritePropertyList(NSDictionary *value, NSString *path, NSError **error) {
    struct stat information;
    if (lstat(path.fileSystemRepresentation, &information) == 0 &&
        (!S_ISREG(information.st_mode) || information.st_nlink != 1)) {
        *error = DigitsMaintenanceError(@"The configuration destination is not a regular file.");
        return NO;
    }
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:value
        format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
    if (!data || ![data writeToFile:path options:NSDataWritingAtomic error:error])
        return NO;
    // Atomic replacement preserves neither a stale owner nor writable modes.
    if (chmod(path.fileSystemRepresentation, 0644) != 0 ||
        (geteuid() == 0 && chown(path.fileSystemRepresentation, 0, 0) != 0)) {
        *error = DigitsMaintenanceError(@"Configuration was written, but its ownership could not be secured.");
        return NO;
    }
    return YES;
}
