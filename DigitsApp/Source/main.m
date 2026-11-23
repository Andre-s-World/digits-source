#import "DigitsApplicationController.h"
#import "DigitsApplicationOperations.h"
#import "Installer/DigitsInstallerActivationSession.h"
#include <string.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        if (argc == 2 && (!strcmp(argv[1], "--installer-activate-touch") ||
                          !strcmp(argv[1], "--installer-deactivate-touch"))) {
            [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
            DigitsInstallerActivationSession *session = [[DigitsInstallerActivationSession alloc]
                initWithActivation:!strcmp(argv[1], "--installer-activate-touch")];
            application.delegate = session;
            [application run];
            return session.exitStatus;
        }
        [application setActivationPolicy:NSApplicationActivationPolicyRegular];
        DigitsApplicationOperations *operations = [[DigitsApplicationOperations alloc] init];
        DigitsApplicationController *controller = [[DigitsApplicationController alloc] initWithActions:operations];
        application.delegate = controller;
        [application run];
        return 0;
    }
}
