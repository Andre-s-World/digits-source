#import "DigitsInstallerInternal.h"
#import <sys/stat.h>

BOOL DigitsInstallerMaintenanceValidateDestinations(NSError **error) {
    NSDictionary *destinations = @{@"/Applications/Digits.app":DIGITS_HOST_IDENTIFIER,
        @"/Library/Extensions/Digits Driver.kext":DIGITS_DRIVER_IDENTIFIER};
    for (NSString *path in destinations) {
        struct stat attributes;
        if (lstat(path.fileSystemRepresentation, &attributes) != 0) {
            if (errno == ENOENT)
                continue;
        } else if (S_ISDIR(attributes.st_mode) && !S_ISLNK(attributes.st_mode)) {
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfURL:
                [NSURL fileURLWithPath:[path stringByAppendingPathComponent:@"Contents/Info.plist"]] error:NULL];
            if ([info[@"CFBundleIdentifier"] isEqual:destinations[path]])
                continue;
        }
        if (error)
            *error = [NSError errorWithDomain:@"local.digits.installer" code:3 userInfo:
                @{NSLocalizedDescriptionKey:@"An installed app or driver has an unexpected identity or path. Nothing was removed."}];
        return NO;
    }
    return YES;
}
