#!/bin/sh
# Run only after the user confirms Stage 1 installation and approves arming.
# The KEXT validates its exact image/route before publication; failure stops here.
set -eu

if [ "$(/usr/bin/id -u)" -ne 0 ]; then
    echo 'This explicit arm-and-capture test requires sudo.' >&2
    exit 1
fi

testing_dir=$(CDPATH= cd -P "$(dirname -- "$0")" && pwd)
project_dir=$(CDPATH= cd -P "$testing_dir/.." && pwd)
expected_version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' \
    "$project_dir/DigitsDriver/Packaging/Driver/Digits Driver.kext/Contents/Info.plist")
# Check the executing driver's published version, not merely the bundle on disk.
driver_status=$("$project_dir/DigitsDriver/Packaging/Driver/digits-driver-ctl" --status)
loaded_version=$(printf '%s\n' "$driver_status" | /usr/bin/plutil -extract DriverVersion raw -o - -)
echo "Digits Driver: loaded=$loaded_version package=$expected_version"
if [ "$loaded_version" != "$expected_version" ]; then
    echo 'STOP: the loaded driver does not match this package. Nothing armed.' >&2
    exit 1
fi
# Publication is one-shot per boot. Reuse the confirmed hook when restarting capture.
armed=$(printf '%s\n' "$driver_status" | /usr/bin/plutil -extract Armed raw -o - -)
hook_installed=$(printf '%s\n' "$driver_status" | /usr/bin/plutil -extract HookInstalled raw -o - -)
case "$armed:$hook_installed" in
    true:true)
        echo 'Digits Driver is already armed. Starting capture without another arm request.'
        ;;
    false:false)
        echo 'Arming the installed Digits Driver for this boot. No installation or USB reset is performed.'
        "$project_dir/DigitsDriver/Packaging/Driver/digits-driver-ctl" --arm XENEON-27C0-0859-EXPERIMENT
        echo 'Arm succeeded. Starting the live report capture; wait for READY.'
        ;;
    *)
        echo "STOP: inconsistent driver state: Armed=$armed HookInstalled=$hook_installed. Nothing armed." >&2
        exit 1
        ;;
esac
exec /bin/sh "$testing_dir/capture-driver.sh"
