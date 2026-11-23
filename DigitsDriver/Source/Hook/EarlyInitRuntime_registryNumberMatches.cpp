// Read one retained registry-property snapshot without sending USB requests.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
bool registryNumberMatches(IORegistryEntry* entry, const char* key, uint64_t expected)
{
    auto* value = entry->copyProperty(key);
    const auto* number = OSDynamicCast(OSNumber, value);
    const bool matches = number && number->unsigned64BitValue() == expected;
    if (value) value->release();
    return matches;
}
}
