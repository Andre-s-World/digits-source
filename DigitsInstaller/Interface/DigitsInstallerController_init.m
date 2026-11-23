#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (Initialization)
- (instancetype)init {
    self = [super init];
    if (self)
        [self configureBackend:[DigitsInstallerBackend new] previewOnly:NO];
    return self;
}
@end
