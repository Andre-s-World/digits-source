#!/usr/bin/env python3
"""Stage the signed Digits package without installing or activating its extension."""
import datetime
import hashlib
import json
from pathlib import Path
import plistlib
import shutil
import subprocess


def main():
    project = Path(__file__).resolve().parent.parent
    products = project / ".build/SignedTouch/Build/Products"
    source = products / "Debug/Digits.app"
    package = project / "DigitsDriver/Packaging/TouchDevelopment"
    if package.exists():
        raise SystemExit("Existing development package preserved; select a new staging directory.")
    subprocess.run(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(source)], check=True)
    package.mkdir(parents=True)
    app = package / "Digits.app"
    subprocess.run(["/usr/bin/ditto", str(source), str(app)], check=True)
    extension = app / "Contents/Library/SystemExtensions/local.digits.touch.dext"
    host_info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
    driver_info = plistlib.loads((extension / "Info.plist").read_bytes())
    paths = [app / "Contents/Info.plist", app / "Contents/MacOS" / host_info["CFBundleExecutable"],
             app / "Contents/_CodeSignature/CodeResources", app / "Contents/embedded.provisionprofile",
             extension / "Info.plist", extension / driver_info["CFBundleExecutable"],
             extension / "_CodeSignature/CodeResources", extension / "embedded.provisionprofile"]
    files = [{"path": str(path.relative_to(package)), "bytes": path.stat().st_size,
              "sha256": hashlib.sha256(path.read_bytes()).hexdigest()} for path in paths]
    report = {
        "product": "Digits Touch", "version": "0.1.6", "teamIdentifier": "PZFJJ4L6SD",
        "hostBundleIdentifier": "local.digits.touch.host", "extensionBundleIdentifier": "local.digits.touch",
        "createdUTC": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "signature": "Apple Development with matching development provisioning profiles",
        "developmentOnly": True, "installed": False, "activated": False,
        "nativeTouchGate": "0.1.6 startup candidate not tested", "baselineDriver": "Digits Driver 0.2.1 archived unchanged",
        "files": files,
    }
    (package / "ARTIFACTS.json").write_text(json.dumps(report, indent=2) + "\n")
    (package / "SHA256SUMS").write_text("".join(item["sha256"] + "  " + item["path"] + "\n" for item in files))
    symbols = package / "DebugSymbols"
    symbols.mkdir()
    for path in (products / "Debug/Digits.app.dSYM", products / "Debug-driverkit/local.digits.touch.dext.dSYM"):
        shutil.copytree(path, symbols / path.name)
    subprocess.run(["/usr/bin/python3", str(project / "Tools/verify-touch-development.py"), str(package)], check=True)
    print("Signed Digits Touch 0.1.6 staged. Nothing installed or activated.")


if __name__ == "__main__":
    main()
