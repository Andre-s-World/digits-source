#!/bin/sh
# Build and sign local candidates only. Never install, activate or load drivers.
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_root"
mkdir -p BuildReports
/usr/bin/xcodebuild -project Digits.xcodeproj -scheme Digits -configuration Debug \
    -derivedDataPath .build/DigitsAppFinal CODE_SIGNING_ALLOWED=YES CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY='Apple Development' DEVELOPMENT_TEAM=YOUR_TEAM_ID -allowProvisioningUpdates build
/usr/bin/env python3 Tools/prepare-installer-payloads.py "$@"
exec /usr/bin/xcodebuild -project Digits.xcodeproj -scheme 'Digits Installer' -configuration Debug \
    -derivedDataPath .build/DigitsInstaller CODE_SIGNING_ALLOWED=YES CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY='Apple Development' DEVELOPMENT_TEAM=YOUR_TEAM_ID -allowProvisioningUpdates build
