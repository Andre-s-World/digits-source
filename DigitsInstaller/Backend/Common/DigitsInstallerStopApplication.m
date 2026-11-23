#import "DigitsInstallerInternal.h"

BOOL DigitsInstallerStopApplication(NSError **error) {
    __block NSArray<NSRunningApplication *> *applications;
    dispatch_sync(dispatch_get_main_queue(), ^{
        applications = [NSRunningApplication runningApplicationsWithBundleIdentifier:DIGITS_HOST_IDENTIFIER];
        for (NSRunningApplication *application in applications)
            [application terminate];
    });
    // Give only the GUI a bounded chance to quit normally. Never kill the
    // DriverKit process, unload a kernel module, or bypass an unsaved-work prompt.
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:10];
    while (deadline.timeIntervalSinceNow > 0) {
        BOOL stopped = YES;
        for (NSRunningApplication *application in applications)
            stopped = stopped && application.terminated;
        if (stopped)
            return YES;
        [NSThread sleepForTimeInterval:0.1];
    }
    if (error)
        *error = [NSError errorWithDomain:@"local.digits.installer" code:2 userInfo:
            @{NSLocalizedDescriptionKey:@"Quit Digits, then try again. The installer did not force it to close."}];
    return NO;
}
