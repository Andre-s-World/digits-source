#!/bin/zsh
# User-space compile/link only. Never runs the helper or installs/loads a driver.
set -eu
task_dir=${0:A:h}
task_sdk=/Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
task_clang=/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
task_output="$task_dir/digits-driver-ctl"
"$task_clang" -target arm64-apple-macos13.0 -isysroot "$task_sdk" \
    -std=c11 -O0 -g -Wall -Wextra -Werror \
    -framework IOKit -framework CoreFoundation \
    -I "$task_dir/ControlTool" "$task_dir"/ControlTool/*.c -o "$task_output"
file "$task_output"
shasum -a 256 "$task_output"
