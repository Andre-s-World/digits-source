// Manual control helper; build and status reads do not install or load drivers.
#include "ControlTool.h"

bool sendControlAction(io_service_t service, CFStringRef action)
{
    const void* keys[] = {CFSTR("Action"), CFSTR("Acknowledgement")};
    const void* values[] = {
        action, CFSTR("XENEON-27C0-0859-EXPERIMENT")
    };
    CFDictionaryRef request = CFDictionaryCreate(kCFAllocatorDefault,
        keys, values, 2, &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks);
    if (request == NULL) {
        fprintf(stderr, "Cannot allocate the action request.\n");
        return false;
    }
    kern_return_t status = IORegistryEntrySetCFProperties(service, request);
    CFRelease(request);
    if (status != KERN_SUCCESS) {
        // A failed action can still leave useful diagnostic properties. Do not
        // retry, send a different action or imply that failure rolled it back.
        fprintf(stderr, "Control action returned %s (0x%08x); no retry sent.\n",
                mach_error_string(status), (unsigned)status);
        return false;
    }
    return true;
}
