#import "DigitsTouchHostController.h"

CFMutableDictionaryRef DigitsTouchCreateTransportMatchingDictionary(void) {
    CFMutableDictionaryRef matching = IOServiceMatching("IOUserService");
    if (matching) {
        NSDictionary *properties =
            @{@"IOUserClass" : @"DigitsUSBTransport", @"IOUserServerName" : @"local.digits.touch"};
        CFDictionarySetValue(matching, CFSTR(kIOPropertyMatchKey),
                             (__bridge CFDictionaryRef)properties);
    }
    return matching;
}
