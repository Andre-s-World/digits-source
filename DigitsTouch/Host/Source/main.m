#import "DigitsTouchHostController.h"
#include <fcntl.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argumentCount, const char *arguments[]) {
    @autoreleasepool {
        BOOL associationOnly = argumentCount == 2 && strcmp(arguments[1], "--associate") == 0;
        BOOL systemAssociation = argumentCount == 2 &&
            strcmp(arguments[1], "--associate-system") == 0;
        BOOL prepareReplacement = argumentCount == 2 &&
            strcmp(arguments[1], "--prepare-replacement") == 0;
        BOOL connectTouch = argumentCount == 2 && strcmp(arguments[1], "--connect-touch") == 0;
        if (argumentCount > 1 && !associationOnly && !systemAssociation &&
            !prepareReplacement && !connectTouch) {
            fprintf(stderr, "Usage: Digits [--associate-system | --associate | --prepare-replacement | --connect-touch]\n");
            return 64;
        }
        if (connectTouch)
            return DigitsTouchConnectPhysicalDevice();
        if (prepareReplacement) {
            SMAppService *service =
                [SMAppService agentServiceWithPlistName:@"local.digits.touch.association.plist"];
            if (service.status == SMAppServiceStatusNotRegistered ||
                service.status == SMAppServiceStatusNotFound)
                return 0;
            // The completion runs only after launchd has reaped the helper. Installers may
            // replace the app then, without racing its running signed executable.
            [service unregisterWithCompletionHandler:^(NSError *error) {
                if (error)
                    fprintf(stderr, "Could not stop automatic Touch: %s\n",
                        error.localizedDescription.UTF8String);
                exit(error ? 1 : 0);
            }];
            dispatch_main();
        }
        __attribute__((objc_precise_lifetime)) DigitsTouchHostController *controller =
            [[DigitsTouchHostController alloc] init];
        controller.associationOnly = associationOnly || systemAssociation;
        controller.systemAssociation = !associationOnly;
        if (controller.associationOnly) {
            if (systemAssociation && getuid() != 0) {
                fprintf(stderr, "Digits Touch: the system association helper must run as root.\n");
                return 77;
            }
            NSURL *support = [NSFileManager.defaultManager
                URLsForDirectory:NSApplicationSupportDirectory
                inDomains:systemAssociation ? NSLocalDomainMask : NSUserDomainMask].firstObject;
            NSURL *directory = [support URLByAppendingPathComponent:@"Digits" isDirectory:YES];
            NSError *error = nil;
            if (!directory || ![NSFileManager.defaultManager createDirectoryAtURL:directory
                withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Digits Touch: cannot prepare association directory: %@", error);
                return 73;
            }
            struct stat directoryInformation = {};
            if (lstat(directory.fileSystemRepresentation, &directoryInformation) != 0 ||
                !S_ISDIR(directoryInformation.st_mode) ||
                directoryInformation.st_uid != getuid() ||
                (directoryInformation.st_mode & (S_IWGRP | S_IWOTH)) != 0) {
                NSLog(@"Digits Touch: association directory ownership or permissions are unsafe");
                return 77;
            }
            NSURL *lockURL = [directory URLByAppendingPathComponent:@"Association.lock"];
            const int lockDescriptor = open(lockURL.fileSystemRepresentation,
                O_CREAT | O_RDWR | O_NOFOLLOW | O_CLOEXEC, S_IRUSR | S_IWUSR);
            struct stat lockInformation = {};
            if (lockDescriptor < 0 || fstat(lockDescriptor, &lockInformation) != 0 ||
                !S_ISREG(lockInformation.st_mode) || lockInformation.st_uid != getuid()) {
                if (lockDescriptor >= 0) close(lockDescriptor);
                NSLog(@"Digits Touch: cannot establish association ownership");
                return 77;
            }
            if (flock(lockDescriptor, LOCK_EX | LOCK_NB) != 0) {
                close(lockDescriptor);
                NSLog(@"Digits Touch: automatic association already has an owner");
                return 0;
            }
            // No NSApplication is created in the worker: Launch Services must still open
            // the independent Digits configuration window when the user clicks the app.
            [controller startAssociation];
            if (!controller.monitoring) {
                NSLog(@"Digits Touch: association startup failed: %@", controller.associationState);
                return 69;
            }
            [controller startBindingWatcher];
            if (!controller.bindingWatcher)
                return 74;
            [controller updateStatus];
            dispatch_main();
        }
        NSApplication *application = NSApplication.sharedApplication;
        [application setActivationPolicy:NSApplicationActivationPolicyRegular];
        application.delegate = controller;
        [application run];
    }
    return 0;
}
