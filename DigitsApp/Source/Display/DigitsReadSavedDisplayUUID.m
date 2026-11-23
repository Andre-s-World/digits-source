#import "DigitsApplicationController.h"

NSString *DigitsReadSavedDisplayUUID(void) {
    NSURL *configurationURL = [NSURL fileURLWithPath:@"/Library/Application Support/Digits/DigitsDisplayBinding.plist"];
    NSData *configurationData = [NSData dataWithContentsOfURL:configurationURL options:NSDataReadingMappedIfSafe error:nil];
    if (!configurationData || configurationData.length > 1024 * 1024)
        return nil;
    id configuration = [NSPropertyListSerialization propertyListWithData:configurationData options:NSPropertyListImmutable format:nil error:nil];
    if (![configuration isKindOfClass:NSDictionary.class])
        return nil;
    id savedUUID = configuration[@"DisplayUUID"];
    if (![savedUUID isKindOfClass:NSString.class] || ![[NSUUID alloc] initWithUUIDString:savedUUID])
        return nil;
    return [savedUUID uppercaseString];
}
