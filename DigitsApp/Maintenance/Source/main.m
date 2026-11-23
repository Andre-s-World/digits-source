#include "DigitsMaintenanceRunStartupCacheSession.h"
#include <string.h>
#import "DigitsMaintenance.h"
#import <stdio.h>

int main(int argc, const char *argv[]) {
    // Keep this C-only branch before any Foundation/autorelease startup.
    if (argc == 2 && strcmp(argv[1], "--startup-cache-session") == 0)
        return DigitsMaintenanceRunStartupCacheSession();
    @autoreleasepool {
        NSError *error = nil;
        BOOL succeeded = DigitsMaintenanceRun(NSProcessInfo.processInfo.arguments, &error);
        NSDictionary *result = @{ @"success":@(succeeded),
            @"message":succeeded ? (NSProcessInfo.processInfo.arguments.count > 1 && [NSProcessInfo.processInfo.arguments[1] isEqual:@"--prepare-binding"] ? @"Offline binding prepared. No installed files changed." : @"Changes saved. Complete any macOS approval in System Settings, then restart your Mac to finish.") :
                                    (error.localizedDescription ?: @"The operation did not complete.") };
        NSData *json = [NSJSONSerialization dataWithJSONObject:result options:0 error:NULL];
        fwrite(json.bytes, 1, json.length, stdout);
        fputc('\n', stdout);
        return succeeded ? 0 : 1;
    }
}
