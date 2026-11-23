// Require an exact registry class before using the pinned controller path.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
bool registryClassMatches(IORegistryEntry* entry, const char* className)
{
    return entry && entry->getMetaClass() &&
        strcmp(entry->getMetaClass()->getClassName(), className) == 0;
}
}
