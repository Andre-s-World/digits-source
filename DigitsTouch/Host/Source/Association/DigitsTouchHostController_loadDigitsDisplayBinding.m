#import "DigitsTouchHostController.h"
#include <fcntl.h>
#include <sys/stat.h>
#include <unistd.h>

@implementation DigitsTouchHostController (BindingConfiguration)
- (NSDictionary *)loadDigitsDisplayBinding {
    NSURL *supportDirectory =
        [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory
                inDomains:self.systemAssociation ? NSLocalDomainMask : NSUserDomainMask]
            .firstObject;
    NSURL *configurationURL =
        [supportDirectory URLByAppendingPathComponent:@"Digits/DigitsDisplayBinding.plist"];
    if (!configurationURL) {
        self.associationState = @"The display configuration directory is unavailable.";
        return nil;
    }
    if (![NSFileManager.defaultManager fileExistsAtPath:configurationURL.path]) {
        self.associationState =
            @"Display setup is pending. Touch stays unbound until a display is selected.";
        return nil;
    }
    NSError *error = nil;
    NSData *contents = nil;
    if (self.systemAssociation) {
        // A root helper must not follow a user-controlled link or trust writable metadata.
        const int descriptor = open(configurationURL.fileSystemRepresentation,
            O_RDONLY | O_NOFOLLOW | O_CLOEXEC);
        struct stat information = {};
        if (descriptor < 0 || fstat(descriptor, &information) != 0 ||
            !S_ISREG(information.st_mode) || information.st_uid != 0 ||
            (information.st_mode & (S_IWGRP | S_IWOTH)) != 0 || information.st_size > 65536) {
            if (descriptor >= 0)
                close(descriptor);
            self.associationState = @"The system display binding must be a root-owned, non-writable regular file. Touch stays unbound.";
            return nil;
        }
        NSFileHandle *file = [[NSFileHandle alloc] initWithFileDescriptor:descriptor
                                                       closeOnDealloc:YES];
        contents = [file readDataToEndOfFileAndReturnError:&error];
    } else {
        contents = [NSData dataWithContentsOfURL:configurationURL options:0 error:&error];
    }
    if (!contents) {
        self.associationState = [NSString
            stringWithFormat:@"Cannot read display binding: %@", error.localizedDescription];
        return nil;
    }
    id decoded = [NSPropertyListSerialization propertyListWithData:contents
                                                           options:NSPropertyListImmutable
                                                            format:NULL
                                                             error:&error];
    if (![decoded isKindOfClass:NSDictionary.class]) {
        self.associationState =
            @"DigitsDisplayBinding.plist is not a valid dictionary. Touch stays unbound.";
        return nil;
    }
    NSDictionary *configuration = decoded;
    for (NSString *key in @[ @"Version", @"USBVendorID", @"USBProductID", @"USBRevision" ]) {
        if (![configuration[key] isKindOfClass:NSNumber.class]) {
            self.associationState = @"Display binding identity fields are missing or invalid.";
            return nil;
        }
    }
    if ([configuration[@"Version"] unsignedIntValue] != 1 ||
        [configuration[@"USBVendorID"] unsignedIntValue] != 0x27c0 ||
        [configuration[@"USBProductID"] unsignedIntValue] != 0x0859 ||
        [configuration[@"USBRevision"] unsignedIntValue] != 0x0150) {
        self.associationState = @"Display binding targets a different protocol or touch device.";
        return nil;
    }
    NSString *uuidText = configuration[@"DisplayUUID"];
    NSUUID *uuid = [uuidText isKindOfClass:NSString.class]
                       ? [[NSUUID alloc] initWithUUIDString:uuidText]
                       : nil;
    if (!uuid || uuidText.length != 36 ||
        [uuid.UUIDString caseInsensitiveCompare:uuidText] != NSOrderedSame) {
        self.associationState = @"The saved display UUID is invalid. Touch stays unbound.";
        return nil;
    }
    if (self.systemAssociation) {
        for (NSString *key in @[ @"DisplayVendorID", @"DisplayProductID", @"DisplaySerialNumber" ]) {
            if (![configuration[key] isKindOfClass:NSNumber.class] ||
                [configuration[key] unsignedLongLongValue] > UINT32_MAX) {
                self.associationState = @"The system display binding requires complete physical EDID identity fields.";
                return nil;
            }
        }
        NSString *hash = configuration[@"DisplayEDIDSHA256"];
        NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:
            @"0123456789abcdefABCDEF"] invertedSet];
        if (![hash isKindOfClass:NSString.class] || hash.length != 64 ||
            [hash rangeOfCharacterFromSet:invalid].location != NSNotFound) {
            self.associationState = @"The system display binding requires the selected display's EDID SHA-256.";
            return nil;
        }
    }
    // Installation does not require this file. The driver receives validated metadata only.
    return configuration;
}
@end
