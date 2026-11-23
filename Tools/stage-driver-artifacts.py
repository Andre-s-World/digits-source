#!/usr/bin/env python3
"""Record built artifacts and debug symbols without executing any driver code."""
import datetime
import hashlib
import json
from pathlib import Path
import plistlib
import shutil
import subprocess


def main():
    project_root = Path(__file__).resolve().parent.parent
    products = project_root / ".build/DerivedData/Build/Products/Debug"
    package = project_root / "DigitsDriver/Packaging/Driver"
    # KEXTs intentionally resolve Apple symbols at load time. Our own missing
    # objects must never be mistaken for kernel imports by dynamic_lookup.
    undefined = subprocess.run(["/usr/bin/nm", "-u", str(package /
        "Digits Driver.kext/Contents/MacOS/DigitsDriver")], check=True,
        capture_output=True, text=True).stdout.splitlines()
    missing = [symbol for symbol in undefined
               if "DigitsEarlyInit" in symbol or "Xeneon" in symbol or "DigitsDisplayBinding" in symbol]
    if missing:
        raise SystemExit("Driver has unresolved authored symbols:\n" + "\n".join(missing))
    # A personality can name an entirely omitted class without creating an
    # undefined link symbol. Require its implementation before packaging.
    defined = subprocess.run(["/usr/bin/nm", "-U", str(package /
        "Digits Driver.kext/Contents/MacOS/DigitsDriver")], check=True,
        capture_output=True, text=True).stdout
    if "DigitsDisplayBindingPublisher10gMetaClass" not in defined:
        raise SystemExit("Driver is missing the display-binding publisher implementation.")
    symbols = package / "DebugSymbols"
    symbols.mkdir(parents=True, exist_ok=True)
    for name in ("Digits Driver.kext.dSYM", "digits-driver-ctl.dSYM"):
        shutil.copytree(products / name, symbols / name, dirs_exist_ok=True)

    payloads = (
        "Digits Driver.kext/Contents/Info.plist",
        "Digits Driver.kext/Contents/MacOS/DigitsDriver",
        "digits-driver-ctl",
    )
    files = []
    for relative_path in payloads:
        path = package / relative_path
        files.append({
            "path": relative_path,
            "bytes": path.stat().st_size,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        })
    (package / "SHA256SUMS").write_text("".join(
        item["sha256"] + "  " + item["path"] + "\n" for item in files
    ))
    information = plistlib.loads((package / payloads[0]).read_bytes())
    manifest = {
        "product": "Digits Driver",
        "version": information["CFBundleVersion"],
        "bundleIdentifier": information["CFBundleIdentifier"],
        "build": "Xcode Debug; arm64e KEXT and arm64 control tool",
        "createdUTC": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "kernelVersion": "Darwin Kernel Version 27.3.0: Fri Oct 30 02:01:13 PDT 2026; root:xnu-13432.60.57~99/RELEASE_ARM64_T6050",
        "pinnedCollectionSHA256": "d1003b5143ffd88439b4d45b6017f587171cfe6855660bed05370a2ea5db9fe9",
        "device": {"vendorID": "27C0", "productID": "0859", "revision": "0150", "route": "00140000"},
        "signature": "unsigned experimental artifacts; no Apple approval or notarization",
        "installed": False,
        "physicalReportGate": "pending user-run test",
        "bootPersistenceGate": "pending user boot test; guarded automatic startup candidate",
        "files": files,
    }
    (package / "ARTIFACTS.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print("Staged artifact hashes and debug symbols; nothing executed or installed.")


if __name__ == "__main__":
    main()
