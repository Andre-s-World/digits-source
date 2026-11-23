#!/bin/sh
# User-run installation/update. Never unload, manually arm, reset USB or reboot.
set -eu
if [ "$(/usr/bin/id -u)" -ne 0 ]; then
    echo 'Run the prepared Digits Driver installer with sudo.' >&2
    exit 1
fi
project_dir=$(CDPATH= cd -P "$(dirname -- "$0")/.." && pwd)
payload_dir="$project_dir/DigitsDriver/Packaging/Driver"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
    "$payload_dir/Digits Driver.kext/Contents/Info.plist")
package="$project_dir/Releases/MacOS-27.3/Components/Digits Driver $version.pkg"
cd "$project_dir/Releases/MacOS-27.3/Components"
/usr/bin/shasum -a 256 -c "$package.sha256"
/usr/sbin/installer -pkg "$package" -target /
echo 'Approve the driver in System Settings if requested, then restart with the Edge connected.'
echo 'Do not manually load or arm it; the next check measures automatic startup.'
