#import "DigitsMaintenance.h"

BOOL DigitsMaintenanceUninstall(NSError **error) {
    // The app first requests normal OS-managed DEXT deactivation. This tool
    // removes known installed files, never a loaded kernel image or system cache.
    NSString *appPath = @"/Applications/Digits.app";
    NSString *driverPath = @"/Library/Extensions/Digits Driver.kext";
    NSDictionary *appInfo = [NSDictionary dictionaryWithContentsOfURL:
        [NSURL fileURLWithPath:[appPath stringByAppendingPathComponent:@"Contents/Info.plist"]] error:NULL];
    NSDictionary *driverInfo = [NSDictionary dictionaryWithContentsOfURL:
        [NSURL fileURLWithPath:[driverPath stringByAppendingPathComponent:@"Contents/Info.plist"]] error:NULL];
    if (([NSFileManager.defaultManager fileExistsAtPath:appPath] &&
         ![appInfo[@"CFBundleIdentifier"] isEqual:@"local.digits.touch.host"]) ||
        ([NSFileManager.defaultManager fileExistsAtPath:driverPath] &&
         ![driverInfo[@"CFBundleIdentifier"] isEqual:@"local.digits.driver"])) {
        *error = DigitsMaintenanceError(@"An installed app or driver has a different identity. Nothing removed.");
        return NO;
    }
    NSString *logDirectory = DigitsMaintenanceCreateLogDirectory(error);
    if (!logDirectory)
        return NO;
    for (NSString *path in @[driverPath, @"/Library/Application Support/Digits/Driver",
                            @"/Library/Application Support/Digits/DigitsDisplayBinding.plist"]) {
        if (!DigitsMaintenanceRemovePath(path, error))
            return NO;
    }
    NSString *output = nil;
    BOOL rebuilt = DigitsMaintenanceRebuildStartupCache(&output, error);
    [output writeToFile:[logDirectory stringByAppendingPathComponent:@"removal-rebuild.log"]
        atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    // Keep the app available if the normal cache update fails so the user can
    // read the actual failure instead of being stranded without its interface.
    if (!rebuilt) {
        *error = DigitsMaintenanceError([NSString stringWithFormat:@"Driver files were removed, but the startup cache update failed. Digits was kept so you can retry. Details: %@", (*error).localizedDescription ?: @"Unknown cache failure"]);
        return NO;
    }
    // Keep diagnostics and every remaining setting until the cache request has
    // succeeded. Then clear only the exact installed Digits locations; project
    // folders, captures and external research/release archives are not searched.
    for (NSString *path in DigitsMaintenanceInstalledSettingsPaths()) {
        if (!DigitsMaintenanceRemovePath(path, error)) {
            *error = DigitsMaintenanceError([NSString stringWithFormat:
                @"Driver removal was requested, but installed settings cleanup did not complete. Digits was kept so you can retry. Details: %@",
                (*error).localizedDescription ?: @"Unknown cleanup failure"]);
            return NO;
        }
    }
    if (!DigitsMaintenanceForgetReceipts(error))
        return NO;
    return DigitsMaintenanceRemovePath(appPath, error);
}
