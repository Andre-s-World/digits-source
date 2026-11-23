#pragma once
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <mach/mach_error.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <sysexits.h>
#include <unistd.h>

extern const char kServiceClass[];
extern const char kAcknowledgement[];
extern const char kDriverBundleIdentifier[];


void printControlUsage(const char* program);
io_service_t findUniqueControlService(void);
bool printControlStatus(io_service_t service);
bool sendControlAction(io_service_t service, CFStringRef action);
