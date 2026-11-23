#import "DigitsTouchHostController.h"
#import <IOUSBHost/IOUSBHost.h>
#include <unistd.h>

int DigitsTouchConnectPhysicalDevice(void) {
    if (geteuid() != 0) {
        fprintf(stderr, "Run with sudo: /Applications/Digits.app/Contents/MacOS/Digits --connect-touch\n");
        return 77;
    }
    NSMutableDictionary *matching = CFBridgingRelease(IOServiceMatching("IOUSBHostDevice"));
    if (!matching)
        return 71;
    matching[@"idVendor"] = @0x27c0;
    matching[@"idProduct"] = @0x0859;
    matching[@"bcdDevice"] = @0x0150;
    io_iterator_t iterator = IO_OBJECT_NULL;
    kern_return_t result = IOServiceGetMatchingServices(kIOMainPortDefault,
        (__bridge_retained CFDictionaryRef)matching, &iterator);
    if (result != KERN_SUCCESS) {
        fprintf(stderr, "Physical device lookup failed: 0x%08x\n", result);
        return 69;
    }
    io_service_t selected = IO_OBJECT_NULL;
    io_service_t candidate;
    NSUInteger deviceCount = 0;
    while ((candidate = IOIteratorNext(iterator)) != IO_OBJECT_NULL) {
        ++deviceCount;
        if (!selected)
            selected = candidate;
        else
            IOObjectRelease(candidate);
    }
    IOObjectRelease(iterator);
    if (deviceCount != 1) {
        if (selected) IOObjectRelease(selected);
        fprintf(stderr, "Expected exactly one 27C0:0859 revision 0150; found %lu. No request sent.\n",
            (unsigned long)deviceCount);
        return 69;
    }
    uint64_t physicalRegistryID = 0;
    result = IORegistryEntryGetRegistryEntryID(selected, &physicalRegistryID);
    if (result != KERN_SUCCESS || !physicalRegistryID) {
        IOObjectRelease(selected);
        fprintf(stderr, "Cannot verify the physical registry identity. No request sent.\n");
        return 69;
    }
    DigitsTouchHostController *controller = [[DigitsTouchHostController alloc] init];
    for (NSDictionary *transport in [controller copyTransportIdentities]) {
        if ([transport[@"PhysicalUSBRegistryID"] unsignedLongLongValue] == physicalRegistryID) {
            IOObjectRelease(selected);
            printf("Digits Touch already owns this physical digitizer. No request sent.\n");
            return 0;
        }
    }
    io_iterator_t interfaces = IO_OBJECT_NULL;
    NSUInteger matchingInterfaces = 0;
    result = IORegistryEntryGetChildIterator(selected, kIOServicePlane, &interfaces);
    if (result == KERN_SUCCESS) {
        io_service_t interface;
        while ((interface = IOIteratorNext(interfaces)) != IO_OBJECT_NULL) {
            CFMutableDictionaryRef copiedProperties = NULL;
            if (IOObjectConformsTo(interface, "IOUSBHostInterface") &&
                IORegistryEntryCreateCFProperties(interface, &copiedProperties,
                    kCFAllocatorDefault, 0) == KERN_SUCCESS && copiedProperties) {
                NSDictionary *properties = CFBridgingRelease(copiedProperties);
                NSDictionary *expected = @{@"bConfigurationValue": @1, @"bInterfaceNumber": @0,
                    @"bAlternateSetting": @0, @"bInterfaceClass": @3,
                    @"bInterfaceSubClass": @0, @"bInterfaceProtocol": @0, @"bNumEndpoints": @1};
                BOOL matches = YES;
                for (NSString *key in expected)
                    matches = matches && [properties[key] isKindOfClass:NSNumber.class] &&
                        [properties[key] isEqualToNumber:expected[key]];
                matchingInterfaces += matches ? 1 : 0;
            }
            IOObjectRelease(interface);
        }
        IOObjectRelease(interfaces);
    }
    if (matchingInterfaces != 1) {
        IOObjectRelease(selected);
        fprintf(stderr, "The exact configuration-1 digitizer interface is absent or ambiguous. No request sent.\n");
        return 69;
    }
    NSError *error = nil;
    printf("Opening only physical 27C0:0859 revision 0150, registry=%llu, with DeviceSeize.\n",
        physicalRegistryID);
    // This opt-in path requests the current configuration once. Unlike DeviceCapture,
    // closing this ordinary client does not request a device reset or power cycle.
    IOUSBHostDevice *device = [[IOUSBHostDevice alloc] initWithIOService:selected
        options:IOUSBHostObjectInitOptionsDeviceSeize queue:nil error:&error interestHandler:nil];
    IOObjectRelease(selected);
    if (!device) {
        fprintf(stderr, "Cannot open this device: %s (%s, 0x%08x). No configuration request sent.\n",
            error.localizedDescription.UTF8String, error.domain.UTF8String, (unsigned int)error.code);
        return 69;
    }
    printf("REQUEST: SET_CONFIGURATION 1, matchInterfaces=YES; setup=0009010000000000\n");
    const BOOL configured = [device configureWithValue:1 matchInterfaces:YES error:&error];
    [device destroy];
    if (!configured) {
        fprintf(stderr, "Reconfiguration failed: %s (%s, 0x%08x). No retry sent.\n",
            error.localizedDescription.UTF8String, error.domain.UTF8String, (unsigned int)error.code);
        return 74;
    }
    printf("Same-configuration request accepted; interfaces are eligible for matching.\n"
        "Check Digits Touch startup logs and physical 0D reports; native input is not yet confirmed.\n");
    return 0;
}
