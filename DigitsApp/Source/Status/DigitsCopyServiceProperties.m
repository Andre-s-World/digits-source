#import "DigitsApplicationController.h"
#import <IOKit/IOKitLib.h>

NSDictionary *DigitsCopyServiceProperties(NSString *serviceClass, NSDictionary *propertyMatch) {
    CFMutableDictionaryRef matching = IOServiceMatching(serviceClass.UTF8String);
    if (!matching)
        return @{};
    if (propertyMatch)
        CFDictionarySetValue(matching, CFSTR(kIOPropertyMatchKey), (__bridge CFDictionaryRef)propertyMatch);
    io_service_t service = IOServiceGetMatchingService(kIOMainPortDefault, matching);
    if (!service)
        return @{};
    CFMutableDictionaryRef properties = NULL;
    kern_return_t result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0);
    IOObjectRelease(service);
    if (result != KERN_SUCCESS || !properties)
        return @{};
    return CFBridgingRelease(properties);
}
