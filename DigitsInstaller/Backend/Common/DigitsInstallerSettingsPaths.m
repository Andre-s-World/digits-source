#import "DigitsInstallerInternal.h"
#import <pwd.h>

NSArray<NSString *> *DigitsInstallerSettingsPaths(void) {
    NSMutableArray<NSString *> *paths = [NSMutableArray arrayWithArray:@[
        @"/Library/Application Support/Digits", @"/Library/Logs/Digits",
        @"/Library/Preferences/local.digits.touch.host.plist",
        @"/Library/Preferences/local.digits.installer.plist",
        @"/Library/LaunchDaemons/local.digits.touch.association.plist"
    ]];
    // Account home directories come from the public system account database.
    // Only Digits' fixed settings/cache suffixes are ever appended to them.
    setpwent();
    struct passwd *account;
    NSMutableSet<NSString *> *homes = [NSMutableSet new];
    while ((account = getpwent())) {
        if (account->pw_uid < 500 || !account->pw_dir)
            continue;
        NSString *home = [NSString stringWithUTF8String:account->pw_dir];
        if (home.length > 1 && home.isAbsolutePath && ![home isEqual:@"/var/empty"])
            [homes addObject:home];
    }
    endpwent();
    for (NSString *home in homes) {
        for (NSString *suffix in @[@"Library/Application Support/Digits", @"Library/Logs/Digits",
            @"Library/Preferences/local.digits.touch.host.plist", @"Library/Preferences/local.digits.installer.plist",
            @"Library/Caches/local.digits.touch.host", @"Library/Caches/local.digits.installer",
            @"Library/Saved Application State/local.digits.touch.host.savedState",
            @"Library/Saved Application State/local.digits.installer.savedState"])
            [paths addObject:[home stringByAppendingPathComponent:suffix]];
    }
    return paths;
}
