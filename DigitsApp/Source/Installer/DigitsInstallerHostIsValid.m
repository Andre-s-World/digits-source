#import "DigitsInstallerActivationSession.h"
#import <Security/Security.h>

BOOL DigitsInstallerHostIsValid(NSString **message) {
    NSBundle *host = NSBundle.mainBundle;
    NSURL *driverURL = [host.bundleURL URLByAppendingPathComponent:
        @"Contents/Library/SystemExtensions/local.digits.touch.dext" isDirectory:YES];
    NSBundle *driver = [NSBundle bundleWithURL:driverURL];
    if (![host.bundlePath isEqualToString:@"/Applications/Digits.app"] ||
        ![host.bundleIdentifier isEqualToString:@"local.digits.touch.host"] ||
        ![driver.bundleIdentifier isEqualToString:@"local.digits.touch"] ||
        ![[driver objectForInfoDictionaryKey:@"CFBundleVersion"] isEqualToString:@"0.1.6"]) {
        *message = @"Installer requests must come from the installed Digits app with its bundled Digits Touch.";
        return NO;
    }
    SecStaticCodeRef code = NULL;
    SecRequirementRef requirement = NULL;
    OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)host.bundleURL, kSecCSDefaultFlags, &code);
    if (status == errSecSuccess)
        status = SecRequirementCreateWithString(CFSTR("anchor apple generic and certificate leaf[subject.OU] = \"YOUR_TEAM_ID\" and identifier \"local.digits.touch.host\""), kSecCSDefaultFlags, &requirement);
    if (status == errSecSuccess)
        status = SecStaticCodeCheckValidity(code, kSecCSStrictValidate | kSecCSCheckNestedCode, requirement);
    if (requirement) CFRelease(requirement);
    if (code) CFRelease(code);
    if (status != errSecSuccess) {
        *message = @"The installed Digits app did not pass code-signature validation.";
        return NO;
    }
    return YES;
}
