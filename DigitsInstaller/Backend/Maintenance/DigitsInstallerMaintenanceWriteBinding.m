#import "DigitsInstallerInternal.h"
#import <sys/stat.h>
#import <unistd.h>

BOOL DigitsInstallerMaintenanceWriteBinding(NSString *uuid, NSError **error) {
    NSUUID *identifier = [[NSUUID alloc] initWithUUIDString:uuid];
    if (!identifier || [identifier.UUIDString isEqual:@"00000000-0000-0000-0000-000000000000"]) {
        if (error)
            *error = [NSError errorWithDomain:@"local.digits.installer" code:4 userInfo:
                @{NSLocalizedDescriptionKey:@"The selected display UUID is invalid."}];
        return NO;
    }
    NSString *directory = @"/Library/Application Support/Digits";
    struct stat attributes;
    if (lstat(directory.fileSystemRepresentation, &attributes) == 0 &&
        (!S_ISDIR(attributes.st_mode) || attributes.st_uid != 0 || (attributes.st_mode & 0022))) {
        if (error)
            *error = [NSError errorWithDomain:@"local.digits.installer" code:5 userInfo:
                @{NSLocalizedDescriptionKey:@"Digits settings must be in a protected system directory."}];
        return NO;
    }
    if (![NSFileManager.defaultManager createDirectoryAtPath:directory withIntermediateDirectories:YES
        attributes:@{NSFilePosixPermissions:@0755} error:error])
        return NO;
    NSDictionary *binding = @{@"Version":@1, @"DisplayUUID":identifier.UUIDString,
        @"USBVendorID":@10176, @"USBProductID":@2137, @"USBRevision":@336, @"USBLocationID":@1310720};
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:binding
        format:NSPropertyListXMLFormat_v1_0 options:0 error:error];
    NSString *path = [directory stringByAppendingPathComponent:@"DigitsDisplayBinding.plist"];
    if (!data || ![data writeToFile:path options:NSDataWritingAtomic error:error])
        return NO;
    if (chown(path.fileSystemRepresentation, 0, 0) != 0 || chmod(path.fileSystemRepresentation, 0644) != 0) {
        if (error)
            *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:
                @{NSLocalizedDescriptionKey:@"The display binding was saved, but its ownership could not be secured."}];
        return NO;
    }
    return YES;
}
