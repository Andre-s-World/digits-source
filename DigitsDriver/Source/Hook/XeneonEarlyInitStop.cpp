// Refuse unload because published services and hook callbacks can retain this module.
#include "EarlyInitRuntime.hpp"

using namespace DigitsEarlyInit;

extern "C" kern_return_t XeneonEarlyInitStop(kmod_info_t*, void*)
{
    // Even before arm, the control service/metaclass can be referenced. Never
    // permit code removal. After arm the explicit OSKext retain is primary.
    return KERN_FAILURE;
}
