#!/bin/zsh
set -eu
task_dir=${0:A:h}
sdk=/Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
toolchain=/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
build_dir="$task_dir/build"
bundle="$build_dir/Digits Driver.kext"
mkdir -p "$bundle/Contents/MacOS" "$build_dir/objects"
common=(-target arm64e-apple-macos27.0 -isysroot "$sdk"
  -isystem "$sdk/System/Library/Frameworks/Kernel.framework/Versions/A/Headers"
  -DKERNEL -DXENEON_SDK27_COMPILE_ONLY_PM_TYPES
  -fptrauth-kernel-abi-version -fptrauth-function-pointer-type-discrimination
  -ffreestanding -fno-builtin -fno-stack-protector -Wall -Wextra -Werror -O0 -g)
objects=()
while IFS= read -r relative_source; do
  object_name=${relative_source//\//_}
  object_path="$build_dir/objects/${object_name%.*}.o"
  if [[ "$relative_source" == *.cpp ]]; then
    "$toolchain/clang++" "${common[@]}" -I "$task_dir" -std=gnu++17 -fapple-kext \
      -fno-exceptions -fno-rtti -Wno-deprecated-declarations \
      -c "$task_dir/$relative_source" -o "$object_path"
  else
    "$toolchain/clang" "${common[@]}" -I "$task_dir" -std=c11 \
      -c "$task_dir/$relative_source" -o "$object_path"
  fi
  objects+=("$object_path")
done < "$task_dir/kernel-sources.txt"
"$toolchain/ld" -arch arm64e -kext -platform_version macos 27.0 27.0 \
  -undefined dynamic_lookup -no_adhoc_codesign "${objects[@]}" \
  -L "$sdk/usr/lib" -lkmod -lkmodc++ -o "$bundle/Contents/MacOS/DigitsDriver"
cp "$task_dir/Info.plist" "$bundle/Contents/Info.plist"
plutil -lint "$bundle/Contents/Info.plist"
file "$bundle/Contents/MacOS/DigitsDriver"
"$toolchain/nm" -u "$bundle/Contents/MacOS/DigitsDriver" > "$build_dir/undefined-symbols.txt"
"$toolchain/otool" -l "$bundle/Contents/MacOS/DigitsDriver" > "$build_dir/load-commands.txt"
shasum -a 256 "$bundle/Contents/MacOS/DigitsDriver" > "$build_dir/executable.sha256"
