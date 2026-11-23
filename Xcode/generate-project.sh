#!/bin/sh
# Generate real source-indexed build targets. Never install, load or run a driver.
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
python3 "$project_root/Xcode/write-touch-development-plist.py"
python3 "$project_root/Xcode/update-source-list.py"
xcodegen --spec "$project_root/project.json" --project "$project_root"
python3 "$project_root/Xcode/set-driver-product-types.py"
