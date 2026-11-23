#include "../../../DigitsApp/Maintenance/Source/DigitsMaintenanceRunStartupCacheSession.h"
#include <string.h>
#import "DigitsInstallerInternal.h"
#import <stdio.h>

int main(int argc, const char *argv[]) {
    // Keep this C-only branch before any Foundation/autorelease startup.
    if (argc == 2 && strcmp(argv[1], "--startup-cache-session") == 0)
        return DigitsMaintenanceRunStartupCacheSession();
    @autoreleasepool {
        NSDictionary *result = DigitsInstallerMaintenanceRun(NSProcessInfo.processInfo.arguments);
        NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:NULL];
        fwrite(data.bytes, 1, data.length, stdout);
        fputc('\n', stdout);
        // Structured success/failure is preserved through osascript. A nonzero
        // child status would otherwise wrap or discard the helper's JSON result.
        return 0;
    }
}
