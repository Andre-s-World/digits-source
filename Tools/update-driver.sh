#!/bin/sh
# Fresh installation and updates use the same versioned, verified installer.
set -eu
project_dir=$(CDPATH= cd -P "$(dirname -- "$0")/.." && pwd)
exec /bin/sh "$project_dir/Tools/install-driver.sh"
