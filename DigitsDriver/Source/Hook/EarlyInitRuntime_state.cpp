#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
// Publication pins this state for the rest of the boot; never duplicate it per file.
EarlyInitRuntime driverRuntime{};
XeneonCreationContexts creationContexts;
}
