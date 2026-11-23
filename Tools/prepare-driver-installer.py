#!/usr/bin/env python3
"""Prepare installer scripts and installed-path checksums from the staged payload."""
import json
from pathlib import Path
import shutil
import sys


def main():
    project = Path(__file__).resolve().parent.parent
    payload = Path(sys.argv[1])
    scripts = Path(sys.argv[2])
    manifest = json.loads((project / "DigitsDriver/Packaging/Driver/ARTIFACTS.json").read_text())
    scripts.mkdir(parents=True)
    for name in ("preinstall", "postinstall"):
        template = project / "DigitsDriver/Packaging/DriverInstaller/Scripts" / (name + ".in")
        (scripts / name).write_text(template.read_text().replace("@DRIVER_VERSION@", manifest["version"]))
        (scripts / name).chmod(0o755)
    shutil.copyfile(project / "DigitsDriver/Packaging/DriverInstaller/Scripts/configure-display-binding.sh",
                    scripts / "configure-display-binding.sh")
    installed_paths = {
        "Digits Driver.kext/Contents/Info.plist": "/Library/Extensions/Digits Driver.kext/Contents/Info.plist",
        "Digits Driver.kext/Contents/MacOS/DigitsDriver": "/Library/Extensions/Digits Driver.kext/Contents/MacOS/DigitsDriver",
        "digits-driver-ctl": "/Library/Application Support/Digits/Driver/digits-driver-ctl",
    }
    support = payload / "Library/Application Support/Digits/Driver"
    (support / "SHA256SUMS").write_text("".join(
        item["sha256"] + "  " + installed_paths[item["path"]] + "\n" for item in manifest["files"]
    ))
    (support / "ARTIFACTS.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
