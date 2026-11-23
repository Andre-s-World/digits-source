#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (AssociationScheduling)
- (void)scheduleAssociationRefresh {
    // Display callbacks may arrive off the main thread. Coalesce notifications there.
    dispatch_async(dispatch_get_main_queue(), ^{
      if (self.shuttingDown || self.refreshScheduled)
          return;
      self.refreshScheduled = YES;
      dispatch_async(dispatch_get_main_queue(), ^{
        self.refreshScheduled = NO;
        if (self.monitoring && !self.shuttingDown)
            [self refreshAssociation];
      });
    });
}
@end
