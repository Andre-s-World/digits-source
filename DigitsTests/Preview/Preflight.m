#import "DigitsTests.h"
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *uuid = argc > 1 ? [NSString stringWithUTF8String:argv[1]] : @"";
        NSDictionary *result = [DigitsTestsReportObserver preflightForDisplayUUID:uuid];
        NSData *json = [NSJSONSerialization dataWithJSONObject:result options:NSJSONWritingPrettyPrinted error:NULL];
        fwrite(json.bytes, 1, json.length, stdout);
        return [result[@"eligible"] boolValue] ? 0 : 1;
    }
}
