#import "DigitsMaintenance.h"

NSDictionary *DigitsMaintenanceCreateBinding(NSString *displayUUID, NSError **error) {
    NSUUID *identifier = [[NSUUID alloc] initWithUUIDString:displayUUID];
    if (!identifier || [identifier.UUIDString isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
        *error = DigitsMaintenanceError(@"Choose a display with a valid UUID.");
        return nil;
    }
    // Keep the existing driver's exact source identity. Choosing a display is
    // not permission to rematch other USB hardware or another touch device.
    return @{ @"Version":@1, @"DisplayUUID":identifier.UUIDString,
        @"USBVendorID":@10176, @"USBProductID":@2137,
        @"USBRevision":@336, @"USBLocationID":@1310720 };
}
