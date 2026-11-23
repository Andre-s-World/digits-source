#import "DigitsInstallerInternal.h"
#import <CommonCrypto/CommonDigest.h>

NSString *DigitsInstallerFileSHA256(NSString *path) {
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:path];
    [stream open];
    CC_SHA256_CTX context;
    CC_SHA256_Init(&context);
    uint8_t buffer[65536];
    NSInteger count;
    while ((count = [stream read:buffer maxLength:sizeof(buffer)]) > 0)
        CC_SHA256_Update(&context, buffer, (CC_LONG)count);
    [stream close];
    if (count < 0)
        return nil;
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_Final(digest, &context);
    NSMutableString *hex = [NSMutableString string];
    for (NSUInteger index = 0; index < sizeof(digest); ++index)
        [hex appendFormat:@"%02x", digest[index]];
    return hex;
}
