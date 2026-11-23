#pragma once
#include "DigitsTouchUserClient.h"
#include "DigitsUSBTransport.h"
#include "DigitsTouchProtocol.h"
#include <DriverKit/IOLib.h>
#include <DriverKit/OSArray.h>
#include <DriverKit/OSData.h>
#include <DriverKit/OSDictionary.h>
#include <DriverKit/OSString.h>
#include <string.h>
struct DigitsTouchUserClient_IVars { DigitsUSBTransport *transport; };
