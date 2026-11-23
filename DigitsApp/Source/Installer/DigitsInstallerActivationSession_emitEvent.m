#import "DigitsInstallerActivationSession.h"
#include <stdio.h>

@implementation DigitsInstallerActivationSession (Events)
- (void)emitEvent:(NSDictionary *)event {
    NSData *data = [NSJSONSerialization dataWithJSONObject:event options:0 error:nil];
    if (!data)
        return;
    fwrite(data.bytes, 1, data.length, stdout);
    fputc('\n', stdout);
    fflush(stdout);
}
@end
