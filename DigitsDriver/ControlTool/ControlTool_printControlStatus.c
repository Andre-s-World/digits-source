// Manual control helper; build and status reads do not install or load drivers.
#include "ControlTool.h"

bool printControlStatus(io_service_t service)
{
    CFMutableDictionaryRef properties = NULL;
    kern_return_t status = IORegistryEntryCreateCFProperties(
        service, &properties, kCFAllocatorDefault, 0);
    if (status != KERN_SUCCESS || properties == NULL) {
        fprintf(stderr, "Cannot read control properties: %s (0x%08x).\n",
                mach_error_string(status), (unsigned)status);
        if (properties != NULL) {
            CFRelease(properties);
        }
        return false;
    }

    CFErrorRef error = NULL;
    CFDataRef xml = CFPropertyListCreateData(kCFAllocatorDefault, properties,
        kCFPropertyListXMLFormat_v1_0, 0, &error);
    CFRelease(properties);
    if (xml == NULL) {
        fprintf(stderr, "Cannot serialize the control properties.\n");
        if (error != NULL) {
            CFRelease(error);
        }
        return false;
    }
    if (error != NULL) {
        CFRelease(error);
    }
    const size_t length = (size_t)CFDataGetLength(xml);
    const size_t written = fwrite(CFDataGetBytePtr(xml), 1, length, stdout);
    CFRelease(xml);
    if (written != length || fflush(stdout) != 0) {
        fprintf(stderr, "Cannot write the complete status output.\n");
        return false;
    }
    return true;
}
