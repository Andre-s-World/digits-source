#import "DigitsInstallerInternal.h"
#import <IOKit/kext/KextManager.h>

NSDictionary *DigitsInstallerInspectInstallation(void) {
    NSMutableArray<NSString *> *components = [NSMutableArray new];
    NSFileManager *manager = NSFileManager.defaultManager;
    if ([manager fileExistsAtPath:@"/Applications/Digits.app"])
        [components addObject:@"Digits app"];
    if ([manager fileExistsAtPath:@"/Library/Extensions/Digits Driver.kext"])
        [components addObject:@"Digits Driver files"];
    for (NSString *path in DigitsInstallerSettingsPaths()) {
        if ([manager fileExistsAtPath:path]) {
            [components addObject:@"Saved Digits settings or support files"];
            break;
        }
    }
    CFDictionaryRef loaded = KextManagerCopyLoadedKextInfo(
        (__bridge CFArrayRef)@[DIGITS_DRIVER_IDENTIFIER], (__bridge CFArrayRef)@[@"CFBundleVersion", @"OSBundleStarted"]);
    NSDictionary *driver = CFBridgingRelease(loaded);
    if (driver[DIGITS_DRIVER_IDENTIFIER])
        [components addObject:@"Digits Driver loaded for this boot"];
    NSDictionary *receipts = DigitsInstallerRunTask(@"/usr/sbin/pkgutil", @[@"--pkgs=^local\\.digits\\.(driver|touch)\\.installer$"]);
    if ([receipts[@"output"] length] && [receipts[@"exitStatus"] intValue] == 0)
        [components addObject:@"Digits installer receipts"];
    NSDictionary *extensions = DigitsInstallerRunTask(@"/usr/bin/systemextensionsctl", @[@"list"]);
    if ([extensions[@"exitStatus"] intValue] == 0) {
        NSRegularExpression *identity = [NSRegularExpression regularExpressionWithPattern:
            @"(?:^|\\s)local\\.digits\\.touch(?:\\s|$)" options:0 error:NULL];
        NSString *listing = extensions[@"output"];
        if ([identity firstMatchInString:listing options:0 range:NSMakeRange(0, listing.length)])
            [components addObject:@"Digits Touch registered with macOS"];
    }
    BOOL installed = components.count > 0;
    return @{ @"installed":@(installed), @"summary":installed ? [components componentsJoinedByString:@" · "] : @"No installed Digits components or settings were found.",
        @"driverApprovalAutomaticallyVerifiable":@NO, @"components":components };
}
