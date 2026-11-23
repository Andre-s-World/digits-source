// Keep preparation failures readable without changing the public status enum.
#include "PinnedControllerInternals.hpp"

namespace XeneonPinnedController {
const char* statusName(Status status)
{
    switch (status) {
    case Status::OK: return "OK";
    case Status::InvalidArgument: return "InvalidArgument";
    case Status::OutputNotEmpty: return "OutputNotEmpty";
    case Status::KernelVersionMismatch: return "KernelVersionMismatch";
    case Status::AnchorMismatch: return "AnchorMismatch";
    case Status::InvalidSlide: return "InvalidSlide";
    case Status::ControllerVptrMismatch: return "ControllerVptrMismatch";
    case Status::TableLayoutMismatch: return "TableLayoutMismatch";
    case Status::TableEntryMismatch: return "TableEntryMismatch";
    case Status::NoMemory: return "NoMemory";
    }
    return "UnknownStatus";
}
}
