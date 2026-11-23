#import "DigitsTests.h"
#import "DigitsTestsReportDescriptor.h"
@implementation DigitsTestsReportObserver (Preflight)
+ (NSDictionary *)preflightForDisplayUUID:(NSString *)uuid
{
    if (![[NSUUID alloc] initWithUUIDString:uuid])
        return @{ @"eligible":@NO, @"reason":@"A valid display binding is required." };
    CFMutableDictionaryRef matching = IOServiceMatching("IOHIDDevice");
    NSDictionary *identity = @{ @"IOUserClass":@"DigitsTouchDevice", @"IOUserServerName":@"local.digits.touch",
        @"Transport":@"Virtual", @"VendorID":@0x27c0, @"ProductID":@0x085a };
    CFDictionarySetValue(matching, CFSTR(kIOPropertyMatchKey), (__bridge CFDictionaryRef)identity);
    io_iterator_t matches = IO_OBJECT_NULL;
    if (IOServiceGetMatchingServices(kIOMainPortDefault, matching, &matches) != KERN_SUCCESS)
        return @{ @"eligible":@NO, @"reason":@"The virtual touch device is unavailable." };
    NSMutableArray *verified = [NSMutableArray array];
    io_registry_entry_t service;
    while ((service = IOIteratorNext(matches))) {
        NSDictionary *properties = DigitsTestsRegistryProperties(service);
        io_name_t name = {0};
        IORegistryEntryGetName(service, name);
        NSData *descriptor = properties[@"ReportDescriptor"];
        id protected = properties[@"IOHIDRequiresTCCAuthorization"];
        BOOL unprotected = !protected || ([protected isKindOfClass:NSNumber.class] && ![protected boolValue]);
        BOOL valid = strcmp(name, "DigitsTouchDevice") == 0 && unprotected &&
            [properties[@"PrimaryUsagePage"] isEqual:@13] && [properties[@"PrimaryUsage"] isEqual:@4] &&
            [properties[@"displayUUID"] isKindOfClass:NSString.class] &&
            [properties[@"displayUUID"] caseInsensitiveCompare:uuid] == NSOrderedSame &&
            [descriptor isKindOfClass:NSData.class] && descriptor.length == sizeof(DigitsTestsExpectedDescriptor) &&
            memcmp(descriptor.bytes, DigitsTestsExpectedDescriptor, descriptor.length) == 0;
        io_registry_entry_t ancestor = IO_OBJECT_NULL;
        IORegistryEntryGetParentEntry(service, kIOServicePlane, &ancestor);
        BOOL providerValid = NO;
        for (NSUInteger depth = 0; ancestor && depth < 8; depth++) {
            NSDictionary *parent = DigitsTestsRegistryProperties(ancestor);
            if ([parent[@"IOUserClass"] isEqual:@"DigitsUSBTransport"] &&
                [parent[@"IOUserServerName"] isEqual:@"local.digits.touch"] &&
                [parent[@"PhysicalUSBRegistryID"] unsignedLongLongValue] &&
                [parent[@"USBInterfaceRegistryID"] unsignedLongLongValue]) {
                // Validate the actual physical ancestor through registry metadata only.
                io_registry_entry_t physical = IOServiceGetMatchingService(kIOMainPortDefault,
                    IORegistryEntryIDMatching([parent[@"PhysicalUSBRegistryID"] unsignedLongLongValue]));
                NSDictionary *hardware = DigitsTestsRegistryProperties(physical);
                providerValid = [hardware[@"idVendor"] isEqual:@0x27c0] &&
                    [hardware[@"idProduct"] isEqual:@0x0859] && [hardware[@"bcdDevice"] isEqual:@0x0150];
                if (physical) IOObjectRelease(physical);
                IOObjectRelease(ancestor); ancestor = IO_OBJECT_NULL;
                break;
            }
            io_registry_entry_t next = IO_OBJECT_NULL;
            IORegistryEntryGetParentEntry(ancestor, kIOServicePlane, &next);
            IOObjectRelease(ancestor); ancestor = next;
        }
        if (ancestor) IOObjectRelease(ancestor);
        uint64_t registryID = 0;
        IORegistryEntryGetRegistryEntryID(service, &registryID);
        if (valid && providerValid) [verified addObject:@{ @"eligible":@YES,
            @"registryID":@(registryID), @"displayUUID":uuid, @"protection":@"absent or false",
            @"descriptorBytes":@(descriptor.length), @"reason":@"Verified virtual Digits Touch input reports." }];
        IOObjectRelease(service);
    }
    IOObjectRelease(matches);
    if (verified.count == 1) return verified.firstObject;
    return @{ @"eligible":@NO, @"reason":verified.count ? @"More than one matching touch device exists." :
        @"No unprotected, bound virtual Digits Touch device matches the verified report layout." };
}
@end
