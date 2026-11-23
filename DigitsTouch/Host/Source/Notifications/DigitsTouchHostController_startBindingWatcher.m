#import "DigitsTouchHostController.h"
#include <fcntl.h>
#include <unistd.h>

@implementation DigitsTouchHostController (BindingWatchStartup)
- (void)startBindingWatcher {
    if (!self.associationOnly || self.bindingWatcher)
        return;
    NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory
        inDomains:self.systemAssociation ? NSLocalDomainMask : NSUserDomainMask].firstObject;
    NSURL *directory = [support URLByAppendingPathComponent:@"Digits" isDirectory:YES];
    const int descriptor = open(directory.fileSystemRepresentation, O_EVTONLY | O_CLOEXEC);
    if (descriptor < 0) {
        NSLog(@"Digits Touch: cannot watch the display binding directory: %s", strerror(errno));
        return;
    }
    // Watch the directory so an atomic plist replacement is observed without polling.
    dispatch_source_t watcher = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, descriptor,
        DISPATCH_VNODE_WRITE | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_DELETE |
        DISPATCH_VNODE_REVOKE, dispatch_get_main_queue());
    if (!watcher) {
        close(descriptor);
        return;
    }
    __weak DigitsTouchHostController *weakController = self;
    dispatch_source_set_event_handler(watcher, ^{
        [weakController scheduleAssociationRefresh];
    });
    dispatch_source_set_cancel_handler(watcher, ^{
        close(descriptor);
    });
    self.bindingWatcher = watcher;
    dispatch_resume(watcher);
}
@end
