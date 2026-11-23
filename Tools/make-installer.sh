#!/bin/sh
# Compile Digits from source for the running macOS kernel and produce Digits Installer.app.
# Builds and signs only. It never installs, loads, arms or activates a driver.
set -eu
project_dir=$(CDPATH= cd -P "$(dirname -- "$0")/.." && pwd)
cd "$project_dir"
export DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}
export PYTHONDONTWRITEBYTECODE=1
if [ ! -d "$DEVELOPER_DIR" ]; then
    echo "Xcode not found at $DEVELOPER_DIR. Set DEVELOPER_DIR to your Xcode's Contents/Developer." >&2
    exit 1
fi

# The team ID is entered by hand wherever the source said YOUR_TEAM_ID, so an
# unconfigured checkout stops here instead of producing a build no Mac will trust.
team=$(/usr/bin/sed -n 's/.*DEVELOPMENT_TEAM=\([A-Z0-9]\{10\}\).*/\1/p' Tools/build-app.sh | /usr/bin/head -1)
unset_files=
for file in Tools/build-app.sh Tools/build-installer.sh Tools/stage-touch-development.py \
    Tools/verify-touch-development.py DigitsApp/Source/Installer/DigitsInstallerHostIsValid.m \
    DigitsInstaller/Backend/Common/DigitsInstallerVerifyCode.m; do
    if [ -z "$team" ] || /usr/bin/grep -q YOUR_TEAM_ID "$file" || ! /usr/bin/grep -q "$team" "$file"; then
        unset_files="$unset_files\n    $file"
    fi
done
if [ -n "$unset_files" ]; then
    printf 'Set your Apple Developer team ID first. Replace YOUR_TEAM_ID with the same ID in:%b\n' \
        "$unset_files" >&2
    exit 1
fi
printf 'Team %s, kernel:\n    %s\n' "$team" "$(/usr/bin/uname -v)"

printf '\n== 1/5 Fit Digits Driver to the running kernel ==\n'
/usr/bin/python3 DigitsDriver/regenerate-kernel-table.py

printf '\n== 2/5 Build Digits Driver ==\n'
# Built from the committed Xcode project. Tools/build-driver.sh also regenerates the
# project from project.json first, which rewrites tracked project files.
mkdir -p BuildReports DigitsDriver/Packaging/Driver
if ! /usr/bin/xcodebuild -project Digits.xcodeproj -scheme 'Digits Driver' \
    -configuration Debug -derivedDataPath .build/DerivedData \
    -destination 'generic/platform=macOS' CODE_SIGNING_ALLOWED=NO build \
    > BuildReports/driver-build.log 2>&1; then
    /usr/bin/tail -70 BuildReports/driver-build.log
    echo 'Digits Driver failed to build. Full log: BuildReports/driver-build.log' >&2
    exit 1
fi
/usr/bin/ditto '.build/DerivedData/Build/Products/Debug/Digits Driver.kext' \
    'DigitsDriver/Packaging/Driver/Digits Driver.kext'
/bin/cp '.build/DerivedData/Build/Products/Debug/digits-driver-ctl' DigitsDriver/Packaging/Driver/
/usr/bin/python3 Tools/stage-driver-artifacts.py

printf '\n== 3/5 Package Digits Driver ==\n'
/bin/sh Tools/package-driver.sh

printf '\n== 4/5 Build and stage Digits Touch ==\n'
/bin/sh Tools/build-touch-development.sh "$team"
staged=DigitsDriver/Packaging/TouchDevelopment
if [ -e "$staged" ]; then
    # The staging tool never overwrites an earlier stage, so keep that one under .build.
    previous=".build/PreviousTouchDevelopment/$(/bin/date -u '+%Y%m%dT%H%M%SZ')"
    mkdir -p .build/PreviousTouchDevelopment
    /bin/mv "$staged" "$previous"
    echo "Previous staged Digits Touch kept at $previous"
fi
/usr/bin/python3 Tools/stage-touch-development.py

printf '\n== 5/5 Build Digits and Digits Installer ==\n'
if ! /bin/sh Tools/build-installer.sh > BuildReports/installer-build.log 2>&1; then
    /usr/bin/tail -70 BuildReports/installer-build.log
    echo 'Digits Installer failed to build. Full log: BuildReports/installer-build.log' >&2
    exit 1
fi
installer="$project_dir/.build/DigitsInstaller/Build/Products/Debug/Digits Installer.app"
test -d "$installer"
printf '\nBUILT: %s\n' "$installer"
echo 'Nothing was installed, loaded or activated. Open the installer when you are ready.'
