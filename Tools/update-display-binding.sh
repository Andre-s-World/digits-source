#!/bin/sh
# One-shot, user-authorized binding update. No helper, runtime unload or USB request.
# --prepare writes offline artifacts only. --apply stages a next-boot configuration.
set -eu
umask 077

mode=${1-}
uuid=${2-}
if { [ "$mode" = '--prepare' ] && [ "$#" -eq 3 ]; } ||
   { [ "$mode" = '--apply' ] && [ "$#" -eq 2 ]; }; then
    :
else
    echo 'Usage: update-display-binding.sh --prepare DISPLAY_UUID NEW_OUTPUT_DIRECTORY' >&2
    echo '       sudo update-display-binding.sh --apply DISPLAY_UUID' >&2
    exit 2
fi
if [ "${#uuid}" -ne 36 ] || ! /usr/bin/printf '%s\n' "$uuid" |
    LC_ALL=C /usr/bin/grep -Eq '^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$'; then
    echo 'The selected display UUID is malformed. Nothing changed.' >&2
    exit 1
fi
if [ "$uuid" = '00000000-0000-0000-0000-000000000000' ]; then
    echo 'The selected display UUID cannot be zero. Nothing changed.' >&2
    exit 1
fi
uuid=$(/usr/bin/printf '%s' "$uuid" | /usr/bin/tr 'a-f' 'A-F')
project_dir=$(CDPATH= cd -P "$(dirname -- "$0")/.." && pwd)
payload_dir="$project_dir/DigitsDriver/Packaging/Driver"
pristine_info="$payload_dir/Digits Driver.kext/Contents/Info.plist"
package="$project_dir/Releases/MacOS-27.3/Components/Digits Driver 0.2.4.pkg"
installed_bundle='/Library/Extensions/Digits Driver.kext'
configuration_dir='/Library/Application Support/Digits'
configuration_path="$configuration_dir/DigitsDisplayBinding.plist"
expected_kernel='Darwin Kernel Version 27.3.0: Fri Oct 30 02:01:13 PDT 2026; root:xnu-13432.60.57~99/RELEASE_ARM64_T6050'

if [ "$mode" = '--apply' ]; then
    if [ "$(/usr/bin/id -u)" -ne 0 ]; then
        echo 'The --apply operation requires administrator authorization.' >&2
        exit 1
    fi
    log_root='/Library/Logs/Digits/Driver'
    /bin/mkdir -p "$log_root"
    /bin/chmod 700 "$log_root"
    output_dir=$(/usr/bin/mktemp -d "$log_root/binding-$(/bin/date -u '+%Y%m%dT%H%M%SZ')-XXXXXX")
    log_path="$output_dir/update.log"
    exec 3>&1
    exec > "$log_path" 2>&1
    phase='preflight'
    trap 'status=$?; if [ "$status" -ne 0 ]; then
        printf "FAILED during %s (status %s). Saved files remain intact.\nLog: %s\n" "$phase" "$status" "$log_path" >&3;
        printf "FAILED during %s (status %s). No automatic rollback or reboot.\n" "$phase" "$status";
    fi' 0
    printf 'Digits binding update: selected UUID=%s\n' "$uuid"
    if [ "$(/usr/bin/uname -v)" != "$expected_kernel" ]; then
        echo 'The running kernel differs from this pinned driver. Nothing installed.' >&2
        exit 1
    fi
    if [ -L "$installed_bundle" ] || [ ! -d "$installed_bundle" ]; then
        echo 'An installed regular Digits Driver 0.2.4 bundle is required.' >&2
        exit 1
    fi
    installed_info="$installed_bundle/Contents/Info.plist"
    installed_identifier=$(/usr/bin/plutil -extract CFBundleIdentifier raw -expect string "$installed_info")
    installed_version=$(/usr/bin/plutil -extract CFBundleVersion raw -expect string "$installed_info")
    if [ "$installed_identifier" != 'local.digits.driver' ] || [ "$installed_version" != '0.2.4' ]; then
        echo 'The installed driver identifier/version differs. Nothing installed.' >&2
        exit 1
    fi
else
    # A new directory preserves previous preparation results instead of replacing them.
    output_dir=$3
    /bin/mkdir -m 700 "$output_dir"
    output_dir=$(CDPATH= cd -P "$output_dir" && pwd)
fi

cd "$payload_dir"
/usr/bin/shasum -a 256 -c SHA256SUMS
cd "$project_dir/Releases/MacOS-27.3/Components"
/usr/bin/shasum -a 256 -c 'Digits Driver 0.2.4.pkg.sha256'
pristine_version=$(/usr/bin/plutil -extract CFBundleVersion raw -expect string "$pristine_info")
pristine_identifier=$(/usr/bin/plutil -extract CFBundleIdentifier raw -expect string "$pristine_info")
if [ "$pristine_version" != '0.2.4' ] || [ "$pristine_identifier" != 'local.digits.driver' ]; then
    echo 'The prepared payload identifier/version differs. Nothing installed.' >&2
    exit 1
fi
cd "$project_dir"

candidate_binding="$output_dir/DigitsDisplayBinding.plist"
configured_info="$output_dir/ConfiguredInfo.plist"
/bin/cat > "$candidate_binding" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>Version</key><integer>1</integer>
<key>DisplayUUID</key><string>$uuid</string>
<key>USBVendorID</key><integer>10176</integer>
<key>USBProductID</key><integer>2137</integer>
<key>USBRevision</key><integer>336</integer>
<key>USBLocationID</key><integer>1310720</integer>
</dict></plist>
EOF
/bin/cp "$pristine_info" "$configured_info"
if [ "$mode" = '--prepare' ]; then
    # Same minimal schema as the importer, without bypassing its root-file rule.
    /usr/bin/plutil -insert 'IOKitPersonalities.Digits Display Binding.DigitsDisplayBinding' \
        -xml "$(/bin/cat "$candidate_binding")" "$configured_info"
    /usr/bin/plutil -lint "$candidate_binding" "$configured_info"
    echo "PREPARED ONLY: $output_dir"
    echo 'No installed files, driver state, USB state or kernel collections changed.'
    exit 0
fi

phase='configuration validation'
if ! /usr/bin/cmp -s "$payload_dir/Digits Driver.kext/Contents/MacOS/DigitsDriver" \
    "$installed_bundle/Contents/MacOS/DigitsDriver"; then
    echo 'The installed executable differs from the verified 0.2.4 payload. Nothing installed.' >&2
    exit 1
fi
/bin/sh "$project_dir/DigitsDriver/Packaging/DriverInstaller/Scripts/configure-display-binding.sh" \
    "$candidate_binding" "$configured_info"
if [ -L "$configuration_dir" ] || [ ! -d "$configuration_dir" ]; then
    echo 'The existing system configuration directory must be a regular directory.' >&2
    exit 1
fi
directory_owner=$(/usr/bin/stat -f '%u' "$configuration_dir")
directory_permissions=$(/usr/bin/stat -f '%Lp' "$configuration_dir")
if [ "$directory_owner" != 0 ] || [ "$((0$directory_permissions & 022))" -ne 0 ]; then
    echo 'The system configuration directory must be root-owned and not group/other writable.' >&2
    exit 1
fi
if [ -e "$configuration_path" ] || [ -L "$configuration_path" ]; then
    if [ -L "$configuration_path" ] || [ ! -f "$configuration_path" ]; then
        echo 'The existing binding must be a regular file.' >&2
        exit 1
    fi
    /bin/cp -p "$configuration_path" "$output_dir/PreviousDisplayBinding.plist"
fi
/bin/cp "$installed_info" "$output_dir/PreviousInstalledInfo.plist"
phase='saving configuration'
temporary_binding=$(/usr/bin/mktemp "$configuration_dir/.DigitsDisplayBinding-XXXXXX")
/bin/cp "$candidate_binding" "$temporary_binding"
/usr/sbin/chown root:wheel "$temporary_binding"
/bin/chmod 644 "$temporary_binding"
/bin/mv -f "$temporary_binding" "$configuration_path"
echo 'Configuration saved; reinstalling the pristine verified package.'
phase='package installation'
/usr/sbin/installer -pkg "$package" -target /
phase='protected staging'
if /usr/bin/kmutil print-diagnostics --bundle-path "$installed_bundle" --do-staging; then
    staging_status=0
else
    staging_status=$?
fi
case "$staging_status" in
    0) ;;
    27|28)
        printf 'PENDING: staging status %s. Complete macOS approval/restart; update is not yet verified.\nLog: %s\n' "$staging_status" "$log_path" >&3
        exit 0
        ;;
    *) exit "$staging_status" ;;
esac
phase='auxiliary collection rebuild request'
if /usr/bin/kmutil rebuild; then
    rebuild_status=0
else
    rebuild_status=$?
fi
case "$rebuild_status" in
    0|27|28)
        printf 'PENDING RESTART: rebuild status %s. Complete any macOS approval, then restart.\n' "$rebuild_status"
        printf 'PENDING RESTART: complete any macOS approval, then restart. No live rebind was attempted.\nLog: %s\n' "$log_path" >&3
        ;;
    *) exit "$rebuild_status" ;;
esac
