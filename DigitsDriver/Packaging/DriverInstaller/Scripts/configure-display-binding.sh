#!/bin/sh
# Import optional machine metadata into the current unsigned KEXT before AuxKC creation.
# This never edits the signed DriverKit bundle, sends USB commands, or changes a live driver.
set -eu
umask 077

if [ "$#" -ne 2 ]; then
    echo 'Usage: configure-display-binding.sh BINDING_PLIST KEXT_INFO_PLIST' >&2
    exit 1
fi
binding_path=$1
information_path=$2
property_path=':IOKitPersonalities:Digits Display Binding:DigitsDisplayBinding'

if [ ! -e "$binding_path" ] && [ ! -L "$binding_path" ]; then
    echo 'No saved display binding. Digits Driver installs normally; Touch stays unbound.'
    exit 0
fi
if [ -L "$binding_path" ] || [ ! -f "$binding_path" ]; then
    echo 'The display binding must be a regular file, not a symbolic link.' >&2
    exit 1
fi
owner=$(/usr/bin/stat -f '%u' "$binding_path")
permissions=$(/usr/bin/stat -f '%Lp' "$binding_path")
size=$(/usr/bin/stat -f '%z' "$binding_path")
if [ "$owner" != 0 ] || [ "$((0$permissions & 022))" -ne 0 ] || [ "$size" -gt 65536 ]; then
    echo 'The saved binding must be root-owned, at most 64 KiB, and not writable by group or others.' >&2
    exit 1
fi
/usr/bin/plutil -lint "$binding_path" >/dev/null
version=$(/usr/bin/plutil -extract Version raw -expect integer "$binding_path")
vendor=$(/usr/bin/plutil -extract USBVendorID raw -expect integer "$binding_path")
product=$(/usr/bin/plutil -extract USBProductID raw -expect integer "$binding_path")
revision=$(/usr/bin/plutil -extract USBRevision raw -expect integer "$binding_path")
uuid=$(/usr/bin/plutil -extract DisplayUUID raw -expect string "$binding_path")
if [ "$version" != 1 ] || [ "$vendor" != 10176 ] || [ "$product" != 2137 ] || [ "$revision" != 336 ]; then
    echo 'The saved display binding targets another protocol or USB controller.' >&2
    exit 1
fi
if [ "${#uuid}" -ne 36 ] || ! /usr/bin/printf '%s\n' "$uuid" | LC_ALL=C /usr/bin/grep -Eq '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'; then
    echo 'The saved display UUID is malformed.' >&2
    exit 1
fi
if [ "$uuid" = '00000000-0000-0000-0000-000000000000' ]; then
    echo 'The saved display UUID cannot be zero.' >&2
    exit 1
fi
if /usr/libexec/PlistBuddy -c 'Print :USBLocationID' "$binding_path" >/dev/null 2>&1; then
    location=$(/usr/bin/plutil -extract USBLocationID raw -expect integer "$binding_path")
    if [ "$location" != 1310720 ]; then
        echo 'The saved USB location does not match the existing driver route guard.' >&2
        exit 1
    fi
fi
# Build a small, known schema. Do not merge arbitrary keys from an external plist
# into IOKit matching data. The route is the current driver's existing exact guard.
/usr/libexec/PlistBuddy -c "Add '$property_path' dict" "$information_path"
/usr/libexec/PlistBuddy -c "Add '$property_path:Version' integer 1" "$information_path"
/usr/libexec/PlistBuddy -c "Add '$property_path:USBVendorID' integer 10176" "$information_path"
/usr/libexec/PlistBuddy -c "Add '$property_path:USBProductID' integer 2137" "$information_path"
/usr/libexec/PlistBuddy -c "Add '$property_path:USBRevision' integer 336" "$information_path"
/usr/libexec/PlistBuddy -c "Add '$property_path:USBLocationID' integer 1310720" "$information_path"
/usr/libexec/PlistBuddy -c "Add '$property_path:DisplayUUID' string $uuid" "$information_path"
/usr/bin/plutil -lint "$information_path"
echo "Saved display binding embedded for next boot: $uuid (USB route 0x00140000)."
