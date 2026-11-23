// Record scalar boot-order evidence without accessing registry or control locks.
#include "EarlyInitRuntime.hpp"

extern "C" void XeneonEarlyInitRecordQualifiedString(void)
{
    using namespace DigitsEarlyInit;
    __atomic_fetch_add(&driverRuntime.qualifiedStringRequests, 1u, __ATOMIC_RELAXED);
    uint64_t unset = 0;
    __atomic_compare_exchange_n(&driverRuntime.firstQualifiedStringTicks, &unset,
        mach_absolute_time(), false, __ATOMIC_RELAXED, __ATOMIC_RELAXED);
}
