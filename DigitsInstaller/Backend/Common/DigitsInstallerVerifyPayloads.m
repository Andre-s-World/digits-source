#import "DigitsInstallerInternal.h"
#import <sys/stat.h>

NSDictionary *DigitsInstallerVerifyPayloads(NSString *directory, NSError **error) {
    NSString *manifestPath = [directory stringByAppendingPathComponent:@"PayloadManifest.json"];
    NSData *data = [NSData dataWithContentsOfFile:manifestPath options:0 error:error];
    id decoded = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:error] : nil;
    NSDictionary *manifest = [decoded isKindOfClass:NSDictionary.class] ? decoded : nil;
    NSDictionary *files = [manifest[@"files"] isKindOfClass:NSDictionary.class] ? manifest[@"files"] : nil;
    NSString *failure = nil;
    if (![manifest[@"schema"] isEqual:@"digits-installer-payloads-v1"] ||
        ![manifest[@"driverVersion"] isEqual:@"0.2.4"] ||
        ![manifest[@"touchVersion"] isEqual:@"0.1.6"] || !files.count ||
        ![manifest[@"appVersion"] isKindOfClass:NSString.class])
        failure = @"The installer payload manifest is missing or has an unsupported format.";
    NSMutableSet *observed = [NSMutableSet new];
    NSDirectoryEnumerator *enumerator = [NSFileManager.defaultManager enumeratorAtPath:directory];
    for (NSString *relative in enumerator) {
        if ([relative isEqualToString:@"PayloadManifest.json"])
            continue;
        NSString *path = [directory stringByAppendingPathComponent:relative];
        struct stat attributes;
        if (lstat(path.fileSystemRepresentation, &attributes) != 0 || S_ISLNK(attributes.st_mode)) {
            failure = @"A payload path could not be verified as a normal file or directory.";
            break;
        }
        if (S_ISDIR(attributes.st_mode))
            continue;
        BOOL known = [relative hasPrefix:@"Digits.app/"] || [relative isEqual:DIGITS_DRIVER_PACKAGE];
        NSString *expected = [files[relative] isKindOfClass:NSString.class] ? files[relative] : nil;
        if (!S_ISREG(attributes.st_mode) || !known || !expected ||
            ![DigitsInstallerFileSHA256(path) isEqualToString:expected.lowercaseString]) {
            failure = @"An installer payload file is missing, changed or outside the manifest.";
            break;
        }
        [observed addObject:relative];
    }
    if (!failure && ![observed isEqualToSet:[NSSet setWithArray:files.allKeys]])
        failure = @"The installer payload files do not match the complete manifest.";
    if (!failure && ![files[DIGITS_DRIVER_PACKAGE] isEqual:DIGITS_DRIVER_PACKAGE_SHA256])
        failure = @"The bundled Digits Driver package is not the frozen verified release.";
    NSString *appPath = [directory stringByAppendingPathComponent:@"Digits.app"];
    NSBundle *app = [NSBundle bundleWithPath:appPath];
    if (!failure && (![[app objectForInfoDictionaryKey:@"CFBundleShortVersionString"] isEqual:manifest[@"appVersion"]] ||
        ![app.bundleIdentifier isEqual:DIGITS_HOST_IDENTIFIER]))
        failure = @"The bundled Digits app version or identity does not match its manifest.";
    if (failure) {
        if (error)
            *error = [NSError errorWithDomain:@"local.digits.installer" code:1
                userInfo:@{NSLocalizedDescriptionKey:failure}];
        return nil;
    }
    if (!DigitsInstallerVerifyCode(appPath, DIGITS_HOST_IDENTIFIER, error))
        return nil;
    return manifest;
}
