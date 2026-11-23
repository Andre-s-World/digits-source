#import "DigitsMaintenance.h"
#import <sys/stat.h>

BOOL DigitsMaintenanceRemovePath(NSString *path, NSError **error) {
    NSMutableSet *allowed = [NSMutableSet setWithArray:DigitsMaintenanceInstalledSettingsPaths()];
    [allowed addObjectsFromArray:@[@"/Library/Extensions/Digits Driver.kext",
        @"/Library/Application Support/Digits/Driver",
        @"/Library/Application Support/Digits/DigitsDisplayBinding.plist",
        @"/Applications/Digits.app"]];
    if (![allowed containsObject:path]) {
        *error = DigitsMaintenanceError(@"The removal path is outside the Digits uninstall boundary.");
        return NO;
    }
    struct stat information;
    if (lstat(path.fileSystemRepresentation, &information) != 0) {
        if (errno == ENOENT)
            return YES;
        *error = DigitsMaintenanceError(@"An installed Digits path could not be inspected.");
        return NO;
    }
    // Fixed settings symlinks are removed themselves, without following them.
    // An app or kernel bundle symlink still fails its original identity guard.
    if (S_ISLNK(information.st_mode) &&
        ([path isEqual:@"/Applications/Digits.app"] ||
         [path isEqual:@"/Library/Extensions/Digits Driver.kext"])) {
        *error = DigitsMaintenanceError(@"An installed Digits path is a symbolic link; removal stopped.");
        return NO;
    }
    return [NSFileManager.defaultManager removeItemAtPath:path error:error];
}
