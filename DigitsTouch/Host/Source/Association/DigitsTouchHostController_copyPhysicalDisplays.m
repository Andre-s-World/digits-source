#import "DigitsTouchHostController.h"
#import <IOKit/graphics/IOGraphicsTypes.h>

@implementation DigitsTouchHostController (PhysicalDisplays)
- (NSArray<DigitsTouchDisplayIdentity *> *)copyPhysicalDisplays {
    NSMutableArray<DigitsTouchDisplayIdentity *> *displays = [NSMutableArray array];
    // Current Apple-silicon ports expose raw EDID. AppleDisplay is the older public
    // display-service path; use it only if the physical-port path has no match.
    for (NSString *serviceClass in @[ @"IOPortTransportStateDisplayPort", @"AppleDisplay" ]) {
        io_iterator_t iterator = IO_OBJECT_NULL;
        if (IOServiceGetMatchingServices(kIOMainPortDefault,
                                         IOServiceMatching(serviceClass.UTF8String),
                                         &iterator) != KERN_SUCCESS)
            continue;
        io_service_t service;
        while ((service = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
            CFMutableDictionaryRef properties = NULL;
            uint64_t registryID = 0;
            kern_return_t result =
                IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0);
            IORegistryEntryGetRegistryEntryID(service, &registryID);
            IOObjectRelease(service);
            if (result != KERN_SUCCESS || !properties)
                continue;
            NSDictionary *information = CFBridgingRelease(properties);
            if ([serviceClass isEqualToString:@"IOPortTransportStateDisplayPort"] &&
                ![information[@"Active"] boolValue])
                continue;
            id descriptor = information[@kIODisplayEDIDKey] ?: information[@"EDID"];
            if (![descriptor isKindOfClass:NSData.class])
                continue;
            DigitsTouchDisplayIdentity *identity =
                DigitsTouchParseDisplayEDID(descriptor, registryID);
            if (identity)
                [displays addObject:identity];
        }
        IOObjectRelease(iterator);
        if (displays.count > 0)
            break;
    }
    return displays;
}
@end
