#import "DigitsInstallerActivationSession.h"

@implementation DigitsInstallerActivationSession (Initialization)
- (instancetype)initWithActivation:(BOOL)activation {
    self = [super init];
    if (self) {
        self.activation = activation;
        self.exitStatus = 1;
    }
    return self;
}
@end
