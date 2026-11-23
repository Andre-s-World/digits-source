#!/bin/sh
# Build with Xcode's matching development profiles; do not install or activate.
set -eu
if [ "$#" -ne 1 ] || [ -z "$1" ]; then
    echo 'Usage: build-touch-development.sh APPLE_DEVELOPMENT_TEAM_ID' >&2
    exit 1
fi
project_dir=$(CDPATH= cd -P "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
mkdir -p BuildReports
build_log="BuildReports/touch-development-signing-$(/bin/date -u '+%Y%m%dT%H%M%SZ').log"
if DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer} \
    /usr/bin/xcodebuild -project Digits.xcodeproj -scheme 'Digits Touch' \
    -configuration Debug -derivedDataPath .build/SignedTouch -allowProvisioningUpdates \
    CODE_SIGNING_ALLOWED=YES CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY='Apple Development' DEVELOPMENT_TEAM="$1" build > "$build_log" 2>&1; then
    echo "Signed development build succeeded. Log: $build_log"
else
    /usr/bin/tail -n 60 "$build_log" >&2
    echo "Build failed. Log: $build_log" >&2
    exit 1
fi
echo 'Build only. Staging and installation are separate explicit steps.'
