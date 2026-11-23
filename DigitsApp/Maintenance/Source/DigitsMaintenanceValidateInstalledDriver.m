#import "DigitsMaintenance.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/stat.h>
#import <sys/sysctl.h>

NSDictionary *DigitsMaintenanceValidateInstalledDriver(NSError **error) {
    NSString *bundle = @"/Library/Extensions/Digits Driver.kext";
    NSString *informationPath = [bundle stringByAppendingPathComponent:@"Contents/Info.plist"];
    NSString *executablePath = [bundle stringByAppendingPathComponent:@"Contents/MacOS/DigitsDriver"];
    for (NSString *path in @[bundle, [bundle stringByAppendingPathComponent:@"Contents"],
                             [bundle stringByAppendingPathComponent:@"Contents/MacOS"],
                             informationPath, executablePath]) {
        struct stat information;
        if (lstat(path.fileSystemRepresentation, &information) != 0 ||
            S_ISLNK(information.st_mode) || information.st_uid != 0 ||
            (information.st_mode & 0022) != 0) {
            *error = DigitsMaintenanceError(@"Digits Driver is missing or has unexpected ownership. No binding was changed.");
            return nil;
        }
    }
    char kernelVersion[1024];
    size_t kernelLength = sizeof(kernelVersion);
    if (sysctlbyname("kern.version", kernelVersion, &kernelLength, NULL, 0) != 0 ||
        strcmp(kernelVersion, "Darwin Kernel Version 27.3.0: Fri Oct 30 02:01:13 PDT 2026; root:xnu-13432.60.57~99/RELEASE_ARM64_T6050") != 0) {
        *error = DigitsMaintenanceError(@"This experimental driver does not match the running kernel. No binding was changed.");
        return nil;
    }
    NSDictionary *information = [NSDictionary dictionaryWithContentsOfURL:
        [NSURL fileURLWithPath:informationPath] error:error];
    if (![information[@"CFBundleIdentifier"] isEqual:@"local.digits.driver"] ||
        ![information[@"CFBundleVersion"] isEqual:@"0.2.4"] ||
        ![information[@"IOKitPersonalities"][@"Digits Display Binding"][@"IOClass"]
            isEqual:@"DigitsDisplayBindingPublisher"]) {
        *error = DigitsMaintenanceError(@"This app requires the verified Digits Driver 0.2.4 binding format.");
        return nil;
    }
    NSData *executable = [NSData dataWithContentsOfFile:executablePath options:0 error:error];
    if (!executable)
        return nil;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(executable.bytes, (CC_LONG)executable.length, digest);
    NSMutableString *hex = [NSMutableString string];
    for (NSUInteger index = 0; index < sizeof(digest); index++)
        [hex appendFormat:@"%02x", digest[index]];
    if (![hex isEqualToString:@"a80e23816142b09c80f40c7d9f3cddfee939f3a931ab44d9bde9e506c648724e"] ||
        [NSFileManager.defaultManager fileExistsAtPath:[bundle stringByAppendingPathComponent:@"Contents/_CodeSignature"]]) {
        *error = DigitsMaintenanceError(@"The installed driver differs from the verified unsigned build. No binding was changed.");
        return nil;
    }
    return information;
}
