#import "DigitsApplicationOperations.h"
#import "DigitsTests.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
@implementation DigitsApplicationOperations (Uninstall)
- (void)uninstallDigitsWithCompletion:(DigitsActionCompletion)completion {
    if (self.uninstallCompletion || self.maintenanceRunning) {
        completion(NO, @"Another Digits change is still running.");
        return;
    }
    // Removal is an explicit user action. Ask macOS to manage its extension;
    // never delete /Library/SystemExtensions or force-unload a running driver.
    // End the app-local read-only observer before requesting OS-managed removal.
    // This closes a normal window, not the working kernel driver.
    [self.tester.window close];
    self.tester = nil;
    self.uninstallCompletion = completion;
    if (self.statusUpdate)
        self.statusUpdate(@"Requesting macOS removal of Digits Touch…");
    OSSystemExtensionRequest *request = [OSSystemExtensionRequest
        deactivationRequestForExtension:@"local.digits.touch" queue:dispatch_get_main_queue()];
    request.delegate = self;
    [OSSystemExtensionManager.sharedManager submitRequest:request];
}
@end

#pragma clang diagnostic pop
