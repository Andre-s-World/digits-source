#import "DigitsInstallerInternal.h"

NSDictionary *DigitsInstallerMaintenanceUninstall(void) {
    NSError *error = nil;
    if (!DigitsInstallerMaintenanceRemoveFiles(YES, &error))
        return DigitsInstallerResult(NO, [@"Uninstall did not complete. Some files may already have been removed. " stringByAppendingString:error.localizedDescription]);
    NSDictionary *cache = DigitsInstallerMaintenanceRebuildStartupCache();
    int status = [cache[@"exitStatus"] intValue];
    if (status != 0)
        return DigitsInstallerResult(NO, [@"Installed Digits files and settings were removed, but the startup cache update did not complete. " stringByAppendingString:cache[@"output"]]);
    return DigitsInstallerResult(YES, @"Installed Digits files, settings, logs and receipts were removed. Complete any macOS approval, then restart to finish removing loaded code. Your projects, captures, release packages and research archives were kept.");
}
