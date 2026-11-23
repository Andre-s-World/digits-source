#!/bin/sh
# Build only Digits and its one-shot command; never install or activate drivers.
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$project_root"
mkdir -p BuildReports
exec /usr/bin/xcodebuild -project Digits.xcodeproj -scheme Digits -configuration Debug \
    -derivedDataPath .build/DigitsApp \
    CODE_SIGNING_ALLOWED=YES CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY='Apple Development' DEVELOPMENT_TEAM=YOUR_TEAM_ID \
    -allowProvisioningUpdates build
