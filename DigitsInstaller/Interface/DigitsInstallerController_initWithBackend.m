#import "DigitsInstallerController.h"
@implementation DigitsInstallerController (BackendInitialization)
- (instancetype)initWithBackend:(DigitsInstallerBackend *)backend previewOnly:(BOOL)previewOnly {
    self = [super init];
    if (self)
        [self configureBackend:backend previewOnly:previewOnly];
    return self;
}
@end
