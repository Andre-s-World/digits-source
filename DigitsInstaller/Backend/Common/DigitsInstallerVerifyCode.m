#import "DigitsInstallerInternal.h"
#import <Security/Security.h>

BOOL DigitsInstallerVerifyCode(NSString *path, NSString *identifier, NSError **error) {
    SecStaticCodeRef code = NULL;
    SecRequirementRef requirement = NULL;
    NSString *expression = [NSString stringWithFormat:
        @"anchor apple generic and certificate leaf[subject.OU] = \"PZFJJ4L6SD\" and identifier \"%@\"", identifier];
    OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)[NSURL fileURLWithPath:path],
                                                 kSecCSDefaultFlags, &code);
    if (status == errSecSuccess)
        status = SecRequirementCreateWithString((__bridge CFStringRef)expression, kSecCSDefaultFlags, &requirement);
    if (status == errSecSuccess)
        status = SecStaticCodeCheckValidity(code, kSecCSStrictValidate | kSecCSCheckNestedCode, requirement);
    if (requirement)
        CFRelease(requirement);
    if (code)
        CFRelease(code);
    if (status != errSecSuccess && error)
        *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:
            @{NSLocalizedDescriptionKey:@"The Digits app signature or publisher identity could not be verified."}];
    return status == errSecSuccess;
}
