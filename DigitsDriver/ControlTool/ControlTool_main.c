// Manual control helper; build and status reads do not install or load drivers.
#include "ControlTool.h"

int main(int argumentCount, char* arguments[])
{
    CFStringRef action = NULL;
    if (argumentCount == 1 || (argumentCount == 2 && strcmp(arguments[1], "--status") == 0)) {
        // Cached property read only: deliberately no refresh action.
    } else if (argumentCount == 2 && strcmp(arguments[1], "--refresh-status") == 0) {
        action = CFSTR("status");
    } else if (argumentCount == 3 &&
               (strcmp(arguments[1], "--arm") == 0 ||
                strcmp(arguments[1], "--disarm") == 0) &&
               strcmp(arguments[2], kAcknowledgement) == 0) {
        action = strcmp(arguments[1], "--arm") == 0 ? CFSTR("arm") : CFSTR("disarm");
    } else {
        printControlUsage(arguments[0]);
        return EX_USAGE;
    }

    if (action != NULL && geteuid() != 0) {
        fprintf(stderr, "This explicit control action requires effective uid 0; "
                        "no action was sent.\n");
        return EX_NOPERM;
    }
    io_service_t service = findUniqueControlService();
    if (service == IO_OBJECT_NULL) {
        return EX_UNAVAILABLE;
    }
    const bool action_succeeded = action == NULL || sendControlAction(service, action);
    const bool status_succeeded = printControlStatus(service);
    IOObjectRelease(service);
    return action_succeeded && status_succeeded ? EX_OK : EX_IOERR;
}
