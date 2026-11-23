#!/bin/sh
# Compile and stage Digits Touch only. Never install, launch or activate it.
set -eu
project_dir=$(CDPATH= cd -P "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}
/bin/sh Xcode/generate-project.sh
mkdir -p BuildReports DigitsDriver/Packaging/Touch
if ! /usr/bin/xcodebuild -project Digits.xcodeproj -scheme 'Digits Touch' \
    -configuration Debug -derivedDataPath .build/DerivedData CODE_SIGNING_ALLOWED=NO build \
    > BuildReports/touch-build.log 2>&1; then
    sed -n '/error:/p; /BUILD FAILED/p; /Undefined symbols/,+12p' BuildReports/touch-build.log
    exit 1
fi
# Remove the superseded local configuration resource from incremental build products.
# Display selection is external metadata and must never be required to load the extension.
/bin/rm -f '.build/DerivedData/Build/Products/Debug/Digits.app/Contents/Resources/DisplayBinding.plist' \
    'DigitsDriver/Packaging/Touch/Digits.app/Contents/Resources/DisplayBinding.plist'
/usr/bin/ditto '.build/DerivedData/Build/Products/Debug/Digits.app' \
    'DigitsDriver/Packaging/Touch/Digits.app'
/usr/bin/python3 Tools/stage-touch-artifacts.py
echo 'BUILT: Digits Touch activation/discovery app and embedded DriverKit extension.'
echo 'Nothing installed, launched or activated. Digits Driver remains unchanged.'
