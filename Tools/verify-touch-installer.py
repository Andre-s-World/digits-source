#!/usr/bin/env python3
"""Check the standalone installer's signed payload and absence of display metadata."""
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess
import sys


def main():
    installer = Path(sys.argv[1])
    expanded = Path(sys.argv[2])
    applications = list(expanded.rglob("Digits.app"))
    if len(applications) != 1:
        raise SystemExit("Expected exactly one Digits app in the installer.")
    application = applications[0]
    subprocess.run(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(application)], check=True)
    if list(expanded.rglob("DigitsDisplayBinding.plist")) or list(expanded.rglob("*.kext")):
        raise SystemExit("Touch installer contains display metadata or a KEXT.")
    info = plistlib.loads((application / "Contents/Info.plist").read_bytes())
    extension = application / "Contents/Library/SystemExtensions/local.digits.touch.dext"
    driver_info = plistlib.loads((extension / "Info.plist").read_bytes())
    if info["CFBundleVersion"] != driver_info["CFBundleVersion"]:
        raise SystemExit("Host and Touch extension versions differ.")
    if list(expanded.rglob("local.digits.touch.association.plist")):
        raise SystemExit("The helper-free installer must not contain an association daemon.")
    digest = hashlib.sha256(installer.read_bytes()).hexdigest()
    installer.with_suffix(".pkg.sha256").write_text(digest + "  " + installer.name + "\n")
    report = {"product": "Digits Touch", "version": info["CFBundleVersion"],
              "installer": installer.name, "sha256": digest,
              "contains": ["Digits.app", "Digits Touch DriverKit extension"],
              "displayBindingIncluded": False, "driverKextIncluded": False, "backgroundHelperIncluded": False,
              "installsOrActivatesDuringPackaging": False,
              "signature": "Development-signed app and DEXT; unsigned installer package"}
    (installer.parent / "TOUCH-RELEASE.json").write_text(json.dumps(report, indent=2) + "\n")
    print("Standalone Touch installer verified; no display-binding file or KEXT included.")


if __name__ == "__main__":
    main()
