#pragma once
#include "EarlyInitRuntime.hpp"

namespace DigitsEarlyInit {
template <typename Function> Function callable(uintptr_t address)
{
    // A cast from signed void* would authenticate with discriminator zero.
    // Preserve the already correctly signed bits when adopting the typed ABI.
    void* signedPointer = ptrauth_sign_unauthenticated(
        reinterpret_cast<void*>(address), ptrauth_key_function_pointer,
        ptrauth_function_pointer_type_discriminator(Function));
    Function function;
    static_assert(sizeof(function) == sizeof(signedPointer), "pointer size");
    __builtin_memcpy(&function, &signedPointer, sizeof(function));
    return function;
}
}
