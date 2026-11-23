#import "DigitsInstallerController.h"
#include <string.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        BOOL preview = argc == 2 && !strcmp(argv[1], "--preview");
        NSApplication *application = NSApplication.sharedApplication;
        [application setActivationPolicy:NSApplicationActivationPolicyRegular];
        DigitsInstallerController *controller = [[DigitsInstallerController alloc]
            initWithBackend:[[DigitsInstallerBackend alloc] init] previewOnly:preview];
        application.delegate = controller;
        [application run];
        return 0;
    }
}
