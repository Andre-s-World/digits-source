#include <mach/kmod.h>
extern kern_return_t XeneonEarlyInitStart(kmod_info_t*, void*);
extern kern_return_t XeneonEarlyInitStop(kmod_info_t*, void*);
extern kmod_start_func_t _start;
extern kmod_stop_func_t _stop;
kmod_start_func_t* _realmain = XeneonEarlyInitStart;
kmod_stop_func_t* _antimain = XeneonEarlyInitStop;
KMOD_EXPLICIT_DECL(local.digits.driver, "0.2.4", _start, _stop)
