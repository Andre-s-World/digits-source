#import "DigitsApplicationController.h"
#import <IOKit/IOKitLib.h>

NSDictionary *DigitsCopyTouchRuntimeState(void) {
    CFMutableDictionaryRef matching = IOServiceMatching("IOUserService");
    if (!matching)
        return @{};
    NSDictionary *identity = @{@"IOUserClass":@"DigitsUSBTransport", @"IOUserServerName":@"local.digits.touch"};
    CFDictionarySetValue(matching, CFSTR(kIOPropertyMatchKey), (__bridge CFDictionaryRef)identity);
    io_iterator_t services = IO_OBJECT_NULL;
    if (IOServiceGetMatchingServices(kIOMainPortDefault, matching, &services) != KERN_SUCCESS)
        return @{};
    io_service_t transport = IOIteratorNext(services);
    io_service_t additional = IOIteratorNext(services);
    IOObjectRelease(services);
    // The current package supports one transport. Ambiguity must never select
    // another touch device or imply that the first match is the user's screen.
    if (!transport || additional) {
        if (transport) IOObjectRelease(transport);
        if (additional) IOObjectRelease(additional);
        return @{};
    }
    CFMutableDictionaryRef copied = NULL;
    if (IORegistryEntryCreateCFProperties(transport, &copied, kCFAllocatorDefault, 0) != KERN_SUCCESS || !copied) {
        IOObjectRelease(transport);
        return @{};
    }
    NSMutableDictionary *state = [(__bridge NSDictionary *)copied mutableCopy];
    CFRelease(copied);
    NSString *bindingState = state[@"BindingState"];
    BOOL bound = [bindingState isEqual:@"Bound; waiting for physical touch"] ||
                 [bindingState isEqual:@"Native touch active"];
    NSString *activeUUID = nil;
    NSUInteger nativeChildren = 0;
    io_iterator_t descendants = IO_OBJECT_NULL;
    if (IORegistryEntryCreateIterator(transport, kIOServicePlane,
        kIORegistryIterateRecursively, &descendants) == KERN_SUCCESS) {
        io_registry_entry_t entry;
        while ((entry = IOIteratorNext(descendants))) {
            io_name_t name = {0};
            if (IOObjectConformsTo(entry, "AppleUserHIDDevice") &&
                IORegistryEntryGetName(entry, name) == KERN_SUCCESS && strcmp(name, "DigitsTouchDevice") == 0) {
                CFTypeRef value = IORegistryEntryCreateCFProperty(entry, CFSTR("displayUUID"), kCFAllocatorDefault, 0);
                id candidate = CFBridgingRelease(value);
                NSUUID *uuid = [candidate isKindOfClass:NSString.class] ? [[NSUUID alloc] initWithUUIDString:candidate] : nil;
                if (uuid) {
                    ++nativeChildren;
                    activeUUID = uuid.UUIDString;
                }
            }
            IOObjectRelease(entry);
        }
        IOObjectRelease(descendants);
    }
    // Before first contact creates its native HID child, the transport exposes
    // successful restoration plus the exact physical provider's boot binding.
    // Check current registry/location selectors rather than trusting a disk file.
    if (nativeChildren == 0 && bound && [state[@"DisplayBindingSource"] isEqual:@"Digits Driver configuration"]) {
        CFTypeRef published = IORegistryEntrySearchCFProperty(transport, kIOServicePlane,
            CFSTR("DigitsDisplayBinding"), kCFAllocatorDefault,
            kIORegistryIterateParents | kIORegistryIterateRecursively);
        id configuration = CFBridgingRelease(published);
        if ([configuration isKindOfClass:NSDictionary.class] &&
            [configuration[@"Version"] isEqual:@1] &&
            [configuration[@"USBVendorID"] isEqual:@0x27c0] &&
            [configuration[@"USBProductID"] isEqual:@0x0859] &&
            [configuration[@"USBRevision"] isEqual:@0x0150] &&
            [configuration[@"PhysicalUSBRegistryID"] isEqual:state[@"PhysicalUSBRegistryID"]] &&
            [configuration[@"USBLocationID"] isEqual:state[@"USBLocationID"]]) {
            id candidate = configuration[@"DisplayUUID"];
            NSUUID *uuid = [candidate isKindOfClass:NSString.class] ? [[NSUUID alloc] initWithUUIDString:candidate] : nil;
            activeUUID = uuid.UUIDString;
        }
    }
    if (bound && nativeChildren <= 1 && activeUUID)
        state[@"ActiveDisplayUUID"] = activeUUID;
    IOObjectRelease(transport);
    return state;
}
