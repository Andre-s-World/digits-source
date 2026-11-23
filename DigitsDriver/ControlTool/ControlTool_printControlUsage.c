// Manual control helper; build and status reads do not install or load drivers.
#include "ControlTool.h"

void printControlUsage(const char* program)
{
    fprintf(stderr,
        "Usage:\n"
        "  %s [--status]\n"
        "  %s --refresh-status\n"
        "  %s --arm XENEON-27C0-0859-EXPERIMENT\n"
        "  %s --disarm XENEON-27C0-0859-EXPERIMENT\n"
        "Status reads cached properties from an already published service.\n"
        "Refresh, arm and disarm require effective uid 0.\n"
        "Arm/disarm also require the exact acknowledgement shown above.\n",
        program, program, program, program);
}
