#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::NewUserClient_Impl(uint32_t type, IOUserClient **userClient) {
    if (!userClient || type != kDigitsTouchUserClientType) return kIOReturnBadArgument;
    *userClient = nullptr;
    if (ivars->stopping || ivars->metadataClientOpen) return kIOReturnExclusiveAccess;
    IOService *service = nullptr;
    kern_return_t result = Create(this, "UserClientProperties", &service);
    if (result != kIOReturnSuccess) return result;
    IOUserClient *client = OSDynamicCast(IOUserClient, service);
    if (!client) {
        if (service) { service->Terminate(0); service->release(); }
        return kIOReturnUnsupported;
    }
    IODispatchQueue *queue = nullptr;
    result = CopyDispatchQueue(kIOServiceDefaultQueueName, &queue);
    if (result == kIOReturnSuccess)
        result = client->SetDispatchQueue(kIOServiceDefaultQueueName, queue);
    if (result == kIOReturnSuccess)
        result = client->SetDispatchQueue(kIOUserClientQueueNameExternalMethod, queue);
    OSSafeReleaseNULL(queue);
    if (result != kIOReturnSuccess) {
        service->Terminate(0);
        service->release();
        return result;
    }
    ivars->metadataClientOpen = true;
    *userClient = client;
    return kIOReturnSuccess;
}
