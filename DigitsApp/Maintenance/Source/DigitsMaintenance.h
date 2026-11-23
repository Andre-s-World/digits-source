#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
BOOL DigitsMaintenanceRun(NSArray<NSString *> *arguments, NSError **error);
BOOL DigitsMaintenanceRunCommand(NSString *executable, NSArray<NSString *> *arguments,
                                 NSString * _Nullable * _Nullable output, NSError **error);
BOOL DigitsMaintenanceRebuildStartupCache(NSString * _Nullable * _Nullable output, NSError **error);
NSDictionary * _Nullable DigitsMaintenanceCreateBinding(NSString *displayUUID, NSError **error);
BOOL DigitsMaintenanceWritePropertyList(NSDictionary *value, NSString *path, NSError **error);
NSDictionary * _Nullable DigitsMaintenanceValidateInstalledDriver(NSError **error);
NSString * _Nullable DigitsMaintenanceCreateLogDirectory(NSError **error);
BOOL DigitsMaintenancePrepareBinding(NSString *displayUUID, NSString *directory, NSError **error);
BOOL DigitsMaintenanceApplyBinding(NSString *displayUUID, NSError **error);
BOOL DigitsMaintenanceUninstall(NSError **error);
NSArray<NSString *> *DigitsMaintenanceInstalledSettingsPaths(void);
BOOL DigitsMaintenanceForgetReceipts(NSError **error);
BOOL DigitsMaintenanceRemovePath(NSString *path, NSError **error);
NSError *DigitsMaintenanceError(NSString *message);
NS_ASSUME_NONNULL_END
