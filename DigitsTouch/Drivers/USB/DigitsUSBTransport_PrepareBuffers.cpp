#include "DigitsUSBTransportState.hpp"
kern_return_t DigitsUSBTransport::PrepareBuffers() {
    kern_return_t result = ivars->interface->CreateIOBuffer(
        kIOMemoryDirectionIn, DigitsUSB::InterruptCapacity, &ivars->interruptBuffer);
    if (result == kIOReturnSuccess)
        result = ivars->interruptBuffer->SetLength(DigitsUSB::InterruptCapacity);
    if (result == kIOReturnSuccess)
        result = ivars->interruptBuffer->GetAddressRange(&ivars->interruptRange);
    if (result == kIOReturnSuccess && ivars->interruptRange.length < DigitsUSB::InterruptCapacity)
        result = kIOReturnNoSpace;
    if (result == kIOReturnSuccess)
        result = ivars->interface->CopyPipe(DigitsUSB::DigitizerEndpoint, &ivars->digitizerPipe);
    IOUSBStandardEndpointDescriptors endpoint{};
    if (result == kIOReturnSuccess)
        result = ivars->digitizerPipe->GetDescriptors(&endpoint, kIOUSBGetEndpointDescriptorOriginal);
    if (result == kIOReturnSuccess &&
        (endpoint.descriptor.bEndpointAddress != DigitsUSB::DigitizerEndpoint ||
         (endpoint.descriptor.bmAttributes & 3) != 3 ||
         USBToHost16(endpoint.descriptor.wMaxPacketSize) != DigitsUSB::InterruptCapacity ||
         endpoint.descriptor.bInterval == 0)) result = kIOReturnUnsupported;
    if (result == kIOReturnSuccess) result = CreateActionReadComplete(0, &ivars->readCompletion);
    return result;
}
