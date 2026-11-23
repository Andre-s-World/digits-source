#import "DigitsTests.h"
NSDictionary *DigitsTestsRegistryProperties(io_registry_entry_t entry)
{
    CFMutableDictionaryRef properties = NULL;
    if (!entry || IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) != KERN_SUCCESS)
        return @{};
    return CFBridgingRelease(properties) ?: @{};
}
