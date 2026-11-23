#import "DigitsApplicationOperations.h"

NSDictionary *DigitsDecodeMaintenanceResult(NSString *output) {
    if (!output.length)
        return nil;
    // osascript wraps a nonzero helper exit in an execution-error prefix/suffix.
    // Preserve the helper's structured failure instead of showing escaped JSON.
    NSRange firstBrace = [output rangeOfString:@"{"];
    NSRange lastBrace = [output rangeOfString:@"}" options:NSBackwardsSearch];
    if (firstBrace.location == NSNotFound || lastBrace.location == NSNotFound ||
        lastBrace.location < firstBrace.location)
        return nil;
    NSString *payload = [output substringWithRange:NSMakeRange(firstBrace.location,
        NSMaxRange(lastBrace) - firstBrace.location)];
    id decoded = [NSJSONSerialization JSONObjectWithData:
        [payload dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    if (![decoded isKindOfClass:NSDictionary.class] ||
        ![decoded[@"success"] isKindOfClass:NSNumber.class] ||
        ![decoded[@"message"] isKindOfClass:NSString.class])
        return nil;
    return decoded;
}
