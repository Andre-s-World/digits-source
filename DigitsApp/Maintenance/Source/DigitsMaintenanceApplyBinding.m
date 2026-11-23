#import "DigitsMaintenance.h"
#import <sys/stat.h>

BOOL DigitsMaintenanceApplyBinding(NSString *displayUUID, NSError **error) {
    NSDictionary *binding = DigitsMaintenanceCreateBinding(displayUUID, error);
    NSDictionary *information = binding ? DigitsMaintenanceValidateInstalledDriver(error) : nil;
    if (!information)
        return NO;
    NSString *directory = @"/Library/Application Support/Digits";
    struct stat protection;
    if (lstat(directory.fileSystemRepresentation, &protection) == 0 &&
        (!S_ISDIR(protection.st_mode) || protection.st_uid != 0 || (protection.st_mode & 0022) != 0)) {
        *error = DigitsMaintenanceError(@"The saved binding directory is not a protected system directory.");
        return NO;
    }
    if (![NSFileManager.defaultManager createDirectoryAtPath:directory
        withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions:@0755} error:error])
        return NO;
    NSString *logDirectory = DigitsMaintenanceCreateLogDirectory(error);
    if (!logDirectory)
        return NO;
    NSString *configurationPath = [directory stringByAppendingPathComponent:@"DigitsDisplayBinding.plist"];
    NSString *informationPath = @"/Library/Extensions/Digits Driver.kext/Contents/Info.plist";
    if (!DigitsMaintenanceWritePropertyList(information,
        [logDirectory stringByAppendingPathComponent:@"PreviousDriverInfo.plist"], error))
        return NO;
    if ([NSFileManager.defaultManager fileExistsAtPath:configurationPath] &&
        ![NSFileManager.defaultManager copyItemAtPath:configurationPath
            toPath:[logDirectory stringByAppendingPathComponent:@"PreviousDisplayBinding.plist"] error:error])
        return NO;
    // Replace only the namespaced data dictionary. The executable, USB guards,
    // other matching personalities and the signed DEXT stay byte-for-byte intact.
    NSMutableDictionary *updatedInformation = information.mutableCopy;
    NSMutableDictionary *personalities = [information[@"IOKitPersonalities"] mutableCopy];
    NSMutableDictionary *publisher = [personalities[@"Digits Display Binding"] mutableCopy];
    publisher[@"DigitsDisplayBinding"] = binding;
    personalities[@"Digits Display Binding"] = publisher;
    updatedInformation[@"IOKitPersonalities"] = personalities;
    if (!DigitsMaintenanceWritePropertyList(binding, configurationPath, error) ||
        !DigitsMaintenanceWritePropertyList(updatedInformation, informationPath, error))
        return NO;
    NSString *stagingOutput = nil;
    BOOL staged = DigitsMaintenanceRunCommand(@"/usr/bin/kmutil",
        @[@"print-diagnostics", @"--bundle-path", @"/Library/Extensions/Digits Driver.kext", @"--do-staging"],
        &stagingOutput, error);
    [stagingOutput writeToFile:[logDirectory stringByAppendingPathComponent:@"staging.log"]
        atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    if (!staged) {
        *error = DigitsMaintenanceError([NSString stringWithFormat:@"The new binding was saved, but staging failed. The previous binding may remain active after restart. Details: %@", (*error).localizedDescription ?: @"Unknown staging failure"]);
        return NO;
    }
    NSString *rebuildOutput = nil;
    BOOL rebuilt = DigitsMaintenanceRebuildStartupCache(&rebuildOutput, error);
    [rebuildOutput writeToFile:[logDirectory stringByAppendingPathComponent:@"rebuild.log"]
        atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    if (!rebuilt)
        *error = DigitsMaintenanceError([NSString stringWithFormat:@"The new binding was saved, but the startup cache update failed. The previous binding may remain active after restart. Details: %@", (*error).localizedDescription ?: @"Unknown cache failure"]);
    return rebuilt;
}
