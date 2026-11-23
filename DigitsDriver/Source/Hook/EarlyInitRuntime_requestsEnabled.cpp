// Read the acceptance flag with the same acquire ordering used by factory callbacks.
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
bool requestsEnabled()
{
    return __atomic_load_n(&driverRuntime.accepting, __ATOMIC_ACQUIRE) != 0;
}
}
