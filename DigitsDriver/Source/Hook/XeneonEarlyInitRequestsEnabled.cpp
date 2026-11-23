// Expose the atomic armed-state check to the string-descriptor subclass.
#include "EarlyInitRuntime.hpp"

using namespace DigitsEarlyInit;

extern "C" bool XeneonEarlyInitRequestsEnabled(void) { return requestsEnabled(); }
