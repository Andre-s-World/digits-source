// Manual control helper; build and status reads do not install or load drivers.
#include "ControlTool.h"

io_service_t findUniqueControlService(void)
{
    CFMutableDictionaryRef match = IOServiceMatching(kServiceClass);
    if (match == NULL) {
        fprintf(stderr, "Cannot create the control-service match.\n");
        return IO_OBJECT_NULL;
    }
    io_iterator_t iterator = IO_OBJECT_NULL;
    // This API consumes the matching dictionary. It discovers existing services;
    // no IOServiceOpen, load request, polling or installation is performed.
    kern_return_t status = IOServiceGetMatchingServices(
        kIOMainPortDefault, match, &iterator);
    if (status != KERN_SUCCESS) {
        fprintf(stderr, "Cannot enumerate the control service: %s (0x%08x).\n",
                mach_error_string(status), (unsigned)status);
        return IO_OBJECT_NULL;
    }

    io_service_t service = IOIteratorNext(iterator);
    io_service_t second = IOIteratorNext(iterator);
    IOObjectRelease(iterator);
    if (service == IO_OBJECT_NULL) {
        fprintf(stderr, "%s is not present; no action was sent.\n",
                kServiceClass);
        return IO_OBJECT_NULL;
    }
    if (second != IO_OBJECT_NULL) {
        IOObjectRelease(second);
        IOObjectRelease(service);
        fprintf(stderr, "Multiple control services exist; no action was sent.\n");
        return IO_OBJECT_NULL;
    }
    if (!IOObjectConformsTo(service, kServiceClass)) {
        IOObjectRelease(service);
        fprintf(stderr, "Control-service class validation failed.\n");
        return IO_OBJECT_NULL;
    }
    CFTypeRef identity = IORegistryEntryCreateCFProperty(
        service, CFSTR("DriverBundleIdentifier"), kCFAllocatorDefault, 0);
    const bool isCandidate = identity != NULL &&
        CFGetTypeID(identity) == CFStringGetTypeID() &&
        CFStringCompare((CFStringRef)identity, CFSTR("local.digits.driver"), 0) ==
            kCFCompareEqualTo;
    if (identity != NULL) {
        CFRelease(identity);
    }
    if (!isCandidate) {
        IOObjectRelease(service);
        fprintf(stderr, "Control service is not %s; no action was sent. "
                        "Never co-load the baseline initializer.\n",
                kDriverBundleIdentifier);
        return IO_OBJECT_NULL;
    }
    return service;
}
