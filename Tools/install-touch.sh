#!/bin/sh
# Install the standalone app/Touch package. Display association is not modified.
set -eu
if [ "$(/usr/bin/id -u)" -ne 0 ]; then
    echo 'Run the prepared Digits Touch installer with sudo.' >&2
    exit 1
fi
project_dir=$(CDPATH= cd -P "$(dirname -- "$0")/.." && pwd)
package_dir="$project_dir/DigitsDriver/Packaging/TouchDevelopment"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
    "$package_dir/Digits.app/Contents/Info.plist")
package="$project_dir/Releases/MacOS-27.3/Components/Digits Touch $version.pkg"
cd "$project_dir/Releases/MacOS-27.3/Components"
/usr/bin/shasum -a 256 -c "$package.sha256"
/usr/sbin/installer -pkg "$package" -target /
echo 'Digits installed. Open Digits and choose Enable Touch; complete normal macOS approval.'
echo 'The installer did not change your display association, activate a driver or reset USB.'
