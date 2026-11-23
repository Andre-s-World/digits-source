#!/bin/sh
# Build and stage only; this never invokes kmutil or runs the control helper.
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_root"
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}
/bin/sh Xcode/generate-project.sh
mkdir -p BuildReports DigitsDriver/Packaging/Driver
if ! /usr/bin/xcodebuild -project Digits.xcodeproj -scheme 'Digits Driver' \
    -configuration Debug -derivedDataPath .build/DerivedData \
    -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build \
    > BuildReports/driver-build.log 2>&1; then
    tail -70 BuildReports/driver-build.log
    exit 1
fi
/usr/bin/ditto '.build/DerivedData/Build/Products/Debug/Digits Driver.kext' \
    'DigitsDriver/Packaging/Driver/Digits Driver.kext'
/bin/cp '.build/DerivedData/Build/Products/Debug/digits-driver-ctl' DigitsDriver/Packaging/Driver/
/usr/bin/python3 Tools/stage-driver-artifacts.py
printf '%s\n' 'BUILT: Digits Driver and its control tool. Nothing installed or loaded.'
