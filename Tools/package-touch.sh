#!/bin/sh
# Build a standalone app/DriverKit installer; no association file or activation.
set -eu
project_dir=$(CDPATH= cd -P "$(dirname -- "$0")/.." && pwd)
package_dir="$project_dir/DigitsDriver/Packaging/TouchDevelopment"
installer_dir="$project_dir/DigitsDriver/Packaging/TouchInstaller"
/usr/bin/python3 "$project_dir/Tools/verify-touch-development.py" "$package_dir"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
    "$package_dir/Digits.app/Contents/Info.plist")
mkdir -p "$project_dir/.build" "$project_dir/Releases/MacOS-27.3/Components" "$project_dir/BuildReports"
staging=$(/usr/bin/mktemp -d "$project_dir/.build/touch-package-XXXXXX")
mkdir -p "$staging/Payload/Applications"
/usr/bin/ditto "$package_dir/Digits.app" "$staging/Payload/Applications/Digits.app"
/bin/chmod 755 "$installer_dir/Scripts/preinstall" "$installer_dir/Scripts/postinstall"
/bin/sh -n "$installer_dir/Scripts/preinstall" "$installer_dir/Scripts/postinstall"
product="$project_dir/Releases/MacOS-27.3/Components/Digits Touch $version.pkg"
/usr/bin/pkgbuild --root "$staging/Payload" --install-location / \
    --identifier local.digits.touch.installer --version "$version" \
    --ownership recommended --component-plist "$installer_dir/Component.plist" \
    --scripts "$installer_dir/Scripts" "$product"
# Expansion verifies the delivered signed app without executing installer scripts.
/usr/sbin/pkgutil --expand-full "$product" "$staging/Expanded"
/usr/bin/python3 "$project_dir/Tools/verify-touch-installer.py" "$product" "$staging/Expanded"
echo "PACKAGED: $product"
echo 'Independent of Digits Driver. No display-binding file, activation or USB action.'
