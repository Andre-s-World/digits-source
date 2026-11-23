#!/usr/bin/env python3
"""Record the real app/DEXT build independently of activation or native-touch proof."""
import datetime
import hashlib
import json
from pathlib import Path
import plistlib
import shutil


def main():
    project_dir = Path(__file__).resolve().parent.parent
    package_dir = project_dir / "DigitsDriver/Packaging/Touch"
    app = package_dir / "Digits.app"
    extension = app / "Contents/Library/SystemExtensions/local.digits.touch.dext"
    app_information = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    driver_information = plistlib.loads((extension / "Info.plist").read_bytes())
    if app_information["CFBundleIdentifier"] != "local.digits.touch.host" or driver_information["CFBundleIdentifier"] != "local.digits.touch":
        raise SystemExit("Unexpected app/extension identity; nothing staged as ready.")
    app_executable = app / "Contents/MacOS" / app_information["CFBundleExecutable"]
    driver_executable = extension / driver_information["CFBundleExecutable"]
    files = []
    for path in (app / "Contents/Info.plist", app_executable, extension / "Info.plist", driver_executable):
        files.append({"path": str(path.relative_to(package_dir)),
                      "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "bytes": path.stat().st_size})
    (package_dir / "SHA256SUMS").write_text("".join(item["sha256"] + "  " + item["path"] + "\n" for item in files))
    symbols = package_dir / "DebugSymbols"
    symbols.mkdir(exist_ok=True)
    products = project_dir / ".build/DerivedData/Build/Products"
    for source in (products / "Debug/Digits.app.dSYM", products / "Debug-driverkit/local.digits.touch.dext.dSYM"):
        shutil.copytree(source, symbols / source.name, dirs_exist_ok=True)
    result = {
        "product": "Digits Touch", "version": driver_information["CFBundleVersion"],
        "createdUTC": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "hostBundleIdentifier": app_information["CFBundleIdentifier"],
        "extensionBundleIdentifier": driver_information["CFBundleIdentifier"],
        "build": "Xcode Debug; macOS and DriverKit SDK27.0; target runtime macOS27.3",
        "files": files, "signature": "unsigned build; entitlement files do not establish Apple approval",
        "installed": False, "activated": False, "nativeTouchGate": "not tested",
        "design": "scoped direct USB/HID transport with event-driven physical-display metadata discovery",
        "workingDriver": "Digits Driver0.2.1 frozen and unchanged",
        "displayConfiguration": "Optional external DigitsDisplayBinding.plist; driver loads unbound without it",
    }
    (package_dir / "ARTIFACTS.json").write_text(json.dumps(result, indent=2) + "\n")
    print("Staged Digits Touch hashes and debug symbols. Activation remains a separate gate.")


if __name__ == "__main__":
    main()
