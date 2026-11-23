#import "DigitsTouchHostController.h"

@implementation DigitsTouchHostController (TransportDiscovery)
- (NSArray<NSDictionary *> *)copyTransportIdentities {
    NSMutableArray<NSDictionary *> *transports = [NSMutableArray array];
    io_iterator_t iterator = IO_OBJECT_NULL;
    if (IOServiceGetMatchingServices(kIOMainPortDefault,
                                     DigitsTouchCreateTransportMatchingDictionary(),
                                     &iterator) != KERN_SUCCESS)
        return transports;
    io_service_t service;
    while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
        CFMutableDictionaryRef properties = NULL;
        uint64_t transportRegistryID = 0;
        IORegistryEntryGetRegistryEntryID(service, &transportRegistryID);
        kern_return_t result =
            IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0);
        IOObjectRelease(service);
        if (result != KERN_SUCCESS || !properties)
            continue;
        NSDictionary *information = CFBridgingRelease(properties);
        NSDictionary *status = information[@"IOUserServiceProperties"];
        if (![status isKindOfClass:NSDictionary.class])
            status = information;
        uint64_t physicalRegistryID = [status[@"PhysicalUSBRegistryID"] unsignedLongLongValue];
        if (physicalRegistryID == 0 || transportRegistryID == 0)
            continue;
        io_service_t physicalDevice = IOServiceGetMatchingService(
            kIOMainPortDefault, IORegistryEntryIDMatching(physicalRegistryID));
        if (!physicalDevice)
            continue;
        CFMutableDictionaryRef physicalProperties = NULL;
        result = IORegistryEntryCreateCFProperties(physicalDevice, &physicalProperties,
                                                   kCFAllocatorDefault, 0);
        BOOL physicalUSBDevice = IOObjectConformsTo(physicalDevice, "IOUSBHostDevice");
        IOObjectRelease(physicalDevice);
        if (result != KERN_SUCCESS || !physicalProperties)
            continue;
        NSDictionary *physical = CFBridgingRelease(physicalProperties);
        if (!physicalUSBDevice || [physical[@"idVendor"] unsignedIntValue] != 0x27c0 ||
            [physical[@"idProduct"] unsignedIntValue] != 0x0859 ||
            [physical[@"bcdDevice"] unsignedIntValue] != 0x0150)
            continue;
        [transports addObject:@{
            @"TransportRegistryID" : @(transportRegistryID),
            @"PhysicalUSBRegistryID" : @(physicalRegistryID),
            @"BindingState" : [status[@"BindingState"] isKindOfClass:NSString.class]
                ? status[@"BindingState"] : @"Digits Touch attached"
        }];
    }
    IOObjectRelease(iterator);
    return transports;
}
@end
