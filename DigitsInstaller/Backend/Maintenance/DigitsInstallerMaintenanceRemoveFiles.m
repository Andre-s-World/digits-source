#import "DigitsInstallerInternal.h"
#import <sys/stat.h>

BOOL DigitsInstallerMaintenanceRemoveFiles(BOOL forgetReceipts, NSError **error) {
    if (!DigitsInstallerMaintenanceValidateDestinations(error))
        return NO;
    NSMutableArray *paths = [NSMutableArray arrayWithArray:DigitsInstallerSettingsPaths()];
    [paths insertObject:@"/Library/Extensions/Digits Driver.kext" atIndex:0];
    [paths addObject:@"/Applications/Digits.app"];
    for (NSString *path in paths) {
        struct stat attributes;
        if (lstat(path.fileSystemRepresentation, &attributes) != 0) {
            if (errno == ENOENT)
                continue;
            if (error)
                *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:
                    @{NSLocalizedDescriptionKey:@"An installed Digits settings path could not be inspected."}];
            return NO;
        }
        // removeItem removes a settings symlink itself, never its target.
        if (![NSFileManager.defaultManager removeItemAtPath:path error:error])
            return NO;
    }
    if (forgetReceipts) {
        for (NSString *identifier in @[@"local.digits.driver.installer", @"local.digits.touch.installer"]) {
            NSDictionary *found = DigitsInstallerRunTask(@"/usr/sbin/pkgutil", @[@"--pkg-info", identifier]);
            if ([found[@"exitStatus"] intValue] != 0)
                continue;
            NSDictionary *forgotten = DigitsInstallerRunTask(@"/usr/sbin/pkgutil", @[@"--forget", identifier]);
            if ([forgotten[@"exitStatus"] intValue] != 0) {
                if (error)
                    *error = [NSError errorWithDomain:@"local.digits.installer" code:6 userInfo:
                        @{NSLocalizedDescriptionKey:@"Digits files were removed, but an installer receipt could not be cleared."}];
                return NO;
            }
        }
    }
    // No collection rebuild or loaded-code change occurs here. Reinstall uses
    // this same disk-only cleanup and reaches its one final reboot later.
    return YES;
}
