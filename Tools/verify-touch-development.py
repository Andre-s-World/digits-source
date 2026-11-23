#!/usr/bin/env python3
"""Verify the prepared local development payload without changing system state."""
import hashlib
import json
from pathlib import Path
import plistlib
import subprocess
import sys


def main():
    package = Path(sys.argv[1]).resolve()
    manifest = json.loads((package / "ARTIFACTS.json").read_text())
    if manifest.get("version") != "0.1.6" or manifest.get("teamIdentifier") != "YOUR_TEAM_ID":
        raise SystemExit("Unexpected development package version or team.")
    if len(manifest.get("files", [])) != 8:
        raise SystemExit("Incomplete development package manifest.")
    for item in manifest["files"]:
        path = (package / item["path"]).resolve()
        if package not in path.parents:
            raise SystemExit("Manifest path is outside the package.")
        data = path.read_bytes()
        if len(data) != item["bytes"] or hashlib.sha256(data).hexdigest() != item["sha256"]:
            raise SystemExit("Development package bytes differ: " + item["path"])
    app = package / "Digits.app"
    extension = app / "Contents/Library/SystemExtensions/local.digits.touch.dext"
    for bundle, info_path, identifier in (
            (app, app / "Contents/Info.plist", "local.digits.touch.host"),
            (extension, extension / "Info.plist", "local.digits.touch")):
        info = plistlib.loads(info_path.read_bytes())
        if info.get("CFBundleIdentifier") != identifier or info.get("CFBundleVersion") != "0.1.6":
            raise SystemExit("Unexpected signed bundle identity or version.")
        if bundle == extension:
            user_client = info["IOKitPersonalities"]["Digits Touch USB Interface"]["UserClientProperties"]
            # The kernel checks this property independently of the development allowance.
            # Development relies on the driver's exact signed-host gate instead.
            if "IOServiceDEXTEntitlements" in user_client:
                raise SystemExit("Development userclient incorrectly requires the release host entitlement.")
        subprocess.run(["/usr/bin/codesign", "--verify", "--strict", str(bundle)], check=True)
        signature = subprocess.run(["/usr/bin/codesign", "-dv", str(bundle)],
                                   capture_output=True, text=True, check=True)
        if "TeamIdentifier=YOUR_TEAM_ID" not in signature.stderr.splitlines():
            raise SystemExit("Unexpected code signing team.")
        signed = subprocess.run(["/usr/bin/codesign", "-d", "--entitlements", "-", "--xml", str(bundle)],
                                capture_output=True, check=True)
        entitlements = plistlib.loads(signed.stdout)
        profile = subprocess.run(["/usr/bin/security", "cms", "-D", "-i",
                                  str(bundle / ("Contents/embedded.provisionprofile" if bundle == app
                                                else "embedded.provisionprofile"))],
                                 capture_output=True, check=True)
        grants = plistlib.loads(profile.stdout)["Entitlements"]
        if bundle == extension:
            # USB entitlement dictionaries must match the development profile exactly.
            # A narrower VID/PID dictionary is NOT a valid subset for taskgated.
            usb_key = "com.apple.developer.driverkit.transport.usb"
            if entitlements.get(usb_key) != [{"idVendor": "*"}] or entitlements[usb_key] != grants.get(usb_key):
                raise SystemExit("Signed development USB entitlement does not exactly match its profile.")
            for key in ("com.apple.developer.driverkit", "com.apple.developer.driverkit.family.hid.device",
                        "com.apple.developer.driverkit.allow-any-userclient-access"):
                if entitlements.get(key) is not True or grants.get(key) is not True:
                    raise SystemExit("Missing signed/profile development capability: " + key)
        elif entitlements.get("com.apple.developer.system-extension.install") is not True or \
                grants.get("com.apple.developer.system-extension.install") is not True:
            raise SystemExit("Missing signed/profile system-extension installation capability.")
    subprocess.run(["/usr/bin/codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    print("Verified Digits Touch 0.1.6: signed host, embedded driver, profiles and manifest.")


if __name__ == "__main__":
    main()
