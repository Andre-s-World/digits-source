#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

@interface DigitsTouchDisplayIdentity : NSObject
@property(nonatomic) uint32_t vendorID;
@property(nonatomic) uint32_t productID;
@property(nonatomic) uint32_t serialNumber;
@property(nonatomic) uint64_t registryID;
@property(nonatomic) CGDirectDisplayID displayID;
@property(nonatomic, copy) NSString *productName;
@property(nonatomic, copy) NSString *serialText;
@property(nonatomic, copy) NSString *displayUUID;
@property(nonatomic, copy) NSString *EDIDSHA256;
@end

DigitsTouchDisplayIdentity *DigitsTouchParseDisplayEDID(NSData *descriptor, uint64_t registryID);
