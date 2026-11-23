#include "DigitsTouchUserClientState.hpp"
kern_return_t DigitsTouchUserClient::ExternalMethod(uint64_t selector,
    IOUserClientMethodArguments *arguments, const IOUserClientMethodDispatch *dispatch,
    OSObject *target, void *reference) {
    (void)dispatch; (void)target; (void)reference;
    if (!ivars->transport || !arguments || !IsAuthorizedHost()) return kIOReturnNotPermitted;
    if (arguments->completion || arguments->scalarInputCount || arguments->scalarOutputCount ||
        arguments->structureInputDescriptor || arguments->structureOutputDescriptor)
        return kIOReturnBadArgument;
    if (selector == kDigitsTouchBindDisplay) {
        if (!arguments->structureInput || arguments->structureInput->getLength() !=
            sizeof(DigitsTouchDisplayBinding) || arguments->structureOutputMaximumSize != 0)
            return kIOReturnBadArgument;
        DigitsTouchDisplayBinding binding{};
        memcpy(&binding, arguments->structureInput->getBytesNoCopy(), sizeof(binding));
        return ivars->transport->BindDisplay(&binding);
    }
    if (arguments->structureInput && arguments->structureInput->getLength() != 0)
        return kIOReturnBadArgument;
    if (selector == kDigitsTouchUnbindDisplay) {
        if (arguments->structureOutputMaximumSize != 0) return kIOReturnBadArgument;
        return ivars->transport->UnbindDisplay();
    }
    if (selector == kDigitsTouchCopyStatus) {
        if (arguments->structureOutputMaximumSize != sizeof(DigitsTouchStatus))
            return kIOReturnBadArgument;
        DigitsTouchStatus status{};
        const kern_return_t result = ivars->transport->CopyStatus(&status);
        if (result != kIOReturnSuccess) return result;
        arguments->structureOutput = OSData::withBytes(&status, sizeof(status));
        return arguments->structureOutput ? kIOReturnSuccess : kIOReturnNoMemory;
    }
    return kIOReturnUnsupported;
}
