#!/bin/sh
# Package the staged binary unchanged. No build, install, load, arm or USB action.
set -eu
umask 022
project_dir=$(CDPATH= cd -P "$(dirname -- "$0")/.." && pwd)
payload_dir="$project_dir/DigitsDriver/Packaging/Driver"
installer_dir="$project_dir/DigitsDriver/Packaging/DriverInstaller"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
    "$payload_dir/Digits Driver.kext/Contents/Info.plist")
cd "$payload_dir"
/usr/bin/shasum -a 256 -c SHA256SUMS
cd "$project_dir"
/bin/sh -n "$installer_dir/Scripts/preinstall.in"
/bin/sh -n "$installer_dir/Scripts/postinstall.in"
/bin/sh -n "$installer_dir/Scripts/configure-display-binding.sh"
mkdir -p .build/DriverPackageComponents Releases/MacOS-27.3/Components BuildReports
staging_dir=$(/usr/bin/mktemp -d "$project_dir/.build/driver-package-XXXXXX")
root_dir="$staging_dir/Payload"
support_dir="$root_dir/Library/Application Support/Digits/Driver"
mkdir -p "$root_dir/Library/Extensions" "$support_dir"
/usr/bin/ditto --noextattr --norsrc "$payload_dir/Digits Driver.kext" \
    "$root_dir/Library/Extensions/Digits Driver.kext"
/bin/cp "$payload_dir/digits-driver-ctl" "$support_dir/digits-driver-ctl"
/usr/bin/python3 "$project_dir/Tools/prepare-driver-installer.py" "$root_dir" "$staging_dir/Scripts"
/bin/chmod -R go-w "$root_dir"
/bin/chmod 755 "$support_dir/digits-driver-ctl" \
    "$staging_dir/Scripts/preinstall" "$staging_dir/Scripts/postinstall"

component="$project_dir/.build/DriverPackageComponents/DigitsDriver-$version-component.pkg"
product="$project_dir/Releases/MacOS-27.3/Components/Digits Driver $version.pkg"
/usr/bin/pkgbuild --root "$root_dir" --install-location / \
    --identifier local.digits.driver.installer --version "$version" \
    --ownership recommended --component-plist "$installer_dir/Component.plist" \
    --scripts "$staging_dir/Scripts" "$component"
/usr/bin/python3 "$project_dir/Tools/write-driver-distribution.py" \
    "$component" "$staging_dir/Distribution.xml"
/usr/bin/productbuild --distribution "$staging_dir/Distribution.xml" \
    --package-path "$project_dir/.build/DriverPackageComponents" \
    --resources "$installer_dir/Resources" "$product"

# Inspect bytes and metadata only. Expanding an installer never runs its scripts.
inspection_dir="$staging_dir/Expanded"
/usr/sbin/pkgutil --expand-full "$product" "$inspection_dir"
/usr/bin/python3 "$project_dir/Tools/write-driver-release.py" "$product" "$inspection_dir"
echo "PACKAGED: $product"
echo 'No driver was rebuilt, installed, loaded or armed.'
