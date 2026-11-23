#!/usr/bin/env python3
"""Derive the development userclient policy without changing release metadata."""

from pathlib import Path
import plistlib


def main():
    project_directory = Path(__file__).resolve().parent.parent
    configuration_directory = project_directory / "DigitsTouch/Configuration"
    release_path = configuration_directory / "Driver-Info.plist"
    development_path = configuration_directory / "Driver-Development-Info.plist"
    with release_path.open("rb") as release_file:
        information = plistlib.load(release_file)
    client_properties = information["IOKitPersonalities"]["Digits Touch USB Interface"][
        "UserClientProperties"
    ]
    expected_entitlements = ["com.apple.developer.driverkit.userclient-access"]
    if client_properties.get("IOServiceDEXTEntitlements") != expected_entitlements:
        raise SystemExit("The release userclient entitlement policy has changed; review it first.")
    # This property adds a second OS gate after the development allow-any grant.
    # Omit it rather than use an empty array, which is a failing entitlement check.
    del client_properties["IOServiceDEXTEntitlements"]
    with development_path.open("wb") as development_file:
        plistlib.dump(information, development_file, fmt=plistlib.FMT_XML, sort_keys=False)


if __name__ == "__main__":
    main()
