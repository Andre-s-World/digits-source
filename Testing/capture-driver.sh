#!/bin/sh
# Capture the current connection only; no arm or USB request is sent here.
set -eu

if [ "$(/usr/bin/id -u)" -ne 0 ]; then
    echo 'Run: sudo /bin/sh Testing/capture-driver.sh' >&2
    exit 1
fi

testing_dir=$(CDPATH= cd -P "$(/usr/bin/dirname "$0")" && /bin/pwd)
project_dir=$(CDPATH= cd -P "$testing_dir/.." && /bin/pwd)
initial_state=$(/sbin/ifconfig XHC0)
restore_down=0
capture_pid=''
parser_pid=''
capture_status=0
parser_status=0
results_dir=''
stream_path=''

cleanup() {
    requested_status=$?
    trap - EXIT INT TERM
    # Signal only the child started here, then let the parser drain through EOF.
    if [ -n "$capture_pid" ]; then
        if /bin/kill -0 "$capture_pid" 2>/dev/null; then
            if ! /bin/kill -INT "$capture_pid"; then
                echo 'Could not stop the owned tcpdump process.' >&2
                capture_status=1
            fi
        fi
        if wait "$capture_pid"; then :; else capture_status=$?; fi
        capture_pid=''
    fi
    if [ -n "$parser_pid" ]; then
        if wait "$parser_pid"; then parser_status=0; else parser_status=$?; fi
        parser_pid=''
    fi
    if [ "$restore_down" -eq 1 ]; then
        if ! /sbin/ifconfig XHC0 down; then
            echo 'Could not restore XHC0 to its original down state.' >&2
            capture_status=1
        fi
    fi
    if [ -n "$results_dir" ]; then
        if [ -f "$results_dir/tcpdump.txt" ]; then /bin/cat "$results_dir/tcpdump.txt" >&2; fi
        if [ -n "$stream_path" ]; then /bin/rm -f "$stream_path"; fi
        # Make this root-created result readable by the user who invoked sudo.
        case "${SUDO_UID-}:${SUDO_GID-}" in
            *[!0-9:]*|:*) ;;
            *:) ;;
            *) /usr/sbin/chown "${SUDO_UID}:${SUDO_GID}" "$results_dir" "$results_dir"/* ;;
        esac
        echo "Saved: $results_dir"
    fi
    if [ "$capture_status" -ne 0 ]; then
        echo "tcpdump/cleanup failed: status=$capture_status" >&2
        exit "$capture_status"
    fi
    if [ "$parser_status" -ne 0 ]; then
        echo "Report parser failed: status=$parser_status" >&2
        exit "$parser_status"
    fi
    exit "$requested_status"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
umask 077
/bin/mkdir -p "$project_dir/Results"
results_dir=$(/usr/bin/mktemp -d "$project_dir/Results/$(/bin/date -u '+%Y%m%dT%H%M%SZ')-XXXXXX")
stream_path="$results_dir/capture.fifo"
/usr/bin/mkfifo "$stream_path"

if ! /usr/bin/printf '%s\n' "$initial_state" | /usr/bin/head -1 | /usr/bin/grep -Eq '<([^>]*,)?UP(,|>)'; then
    /sbin/ifconfig XHC0 up
    restore_down=1
fi

echo "Capture: $results_dir/capture.pcap"
echo 'Keep the Edge connected. Wait for READY, then touch the screen. Ctrl-C stops; no timer.'
/usr/bin/python3 -u "$testing_dir/read-driver-reports.py" --output "$results_dir" < "$stream_path" &
parser_pid=$!
# Disable kernel capture batching as well as flushing each packet to the parser.
/usr/sbin/tcpdump -i XHC0 --immediate-mode -U -s 0 -w - > "$stream_path" 2> "$results_dir/tcpdump.txt" &
capture_pid=$!

if wait "$parser_pid"; then parser_status=0; else parser_status=$?; fi
parser_pid=''
exit "$parser_status"
