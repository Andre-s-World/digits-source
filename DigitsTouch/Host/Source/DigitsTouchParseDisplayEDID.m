#import "DigitsTouchDisplayIdentity.h"
#import <CommonCrypto/CommonDigest.h>

DigitsTouchDisplayIdentity *DigitsTouchParseDisplayEDID(NSData *descriptor, uint64_t registryID) {
    static const uint8_t expectedHeader[] = {0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00};
    if (descriptor.length < 128 || registryID == 0)
        return nil;
    const uint8_t *bytes = descriptor.bytes;
    if (memcmp(bytes, expectedHeader, sizeof(expectedHeader)) != 0)
        return nil;
    uint8_t checksum = 0;
    for (NSUInteger offset = 0; offset < 128; ++offset)
        checksum = (uint8_t)(checksum + bytes[offset]);
    if (checksum != 0)
        return nil;

    uint32_t vendorID = ((uint32_t)bytes[8] << 8) | bytes[9];
    uint32_t productID = bytes[10] | ((uint32_t)bytes[11] << 8);
    if (vendorID != 0x0e58 || productID != 0xed00)
        return nil;
    NSString *productName = @"";
    NSString *serialText = @"";
    for (NSUInteger offset = 54; offset + 18 <= 126; offset += 18) {
        if (bytes[offset] != 0 || bytes[offset + 1] != 0 || bytes[offset + 2] != 0)
            continue;
        NSString *text = [[NSString alloc] initWithBytes:bytes + offset + 5
                                                  length:13
                                                encoding:NSASCIIStringEncoding];
        text =
            [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (bytes[offset + 3] == 0xfc)
            productName = text ?: @"";
        if (bytes[offset + 3] == 0xff)
            serialText = text ?: @"";
    }
    if (![productName.uppercaseString isEqualToString:@"XENEON EDGE"])
        return nil;

    DigitsTouchDisplayIdentity *identity = [[DigitsTouchDisplayIdentity alloc] init];
    identity.vendorID = vendorID;
    identity.productID = productID;
    identity.serialNumber = bytes[12] | ((uint32_t)bytes[13] << 8) | ((uint32_t)bytes[14] << 16) |
                            ((uint32_t)bytes[15] << 24);
    identity.registryID = registryID;
    identity.productName = productName;
    identity.serialText = serialText;
    // Bind a machine-wide saved UUID to the exact physical EDID, without requiring
    // a logged-in WindowServer session to supply a session-local display number.
    uint8_t digest[CC_SHA256_DIGEST_LENGTH] = {};
    if (descriptor.length > UINT32_MAX ||
        !CC_SHA256(descriptor.bytes, (CC_LONG)descriptor.length, digest))
        return nil;
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; ++index)
        [hash appendFormat:@"%02x", digest[index]];
    identity.EDIDSHA256 = hash;
    return identity;
}
