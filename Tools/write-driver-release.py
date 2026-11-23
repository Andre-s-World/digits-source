#!/usr/bin/env python3
"""Verify the installer contains the staged artifacts and record release hashes."""
import datetime
import hashlib
import json
from pathlib import Path
import plistlib
import sys
import xml.etree.ElementTree as ET


def main():
    project_dir = Path(__file__).resolve().parent.parent
    product_path = Path(sys.argv[1])
    expanded_dir = Path(sys.argv[2])
    artifact = json.loads((project_dir / "DigitsDriver/Packaging/Driver/ARTIFACTS.json").read_text())
    bundles = list(expanded_dir.rglob("Digits Driver.kext"))
    if len(bundles) != 1:
        raise SystemExit("Expected exactly one driver in the expanded installer.")
    bundle = bundles[0]
    helpers = list(expanded_dir.rglob("digits-driver-ctl"))
    if len(helpers) != 1:
        raise SystemExit("Expected exactly one control helper in the expanded installer.")
    expected_paths = {
        "Digits Driver.kext/Contents/Info.plist": bundle / "Contents/Info.plist",
        "Digits Driver.kext/Contents/MacOS/DigitsDriver": bundle / "Contents/MacOS/DigitsDriver",
        "digits-driver-ctl": helpers[0],
    }
    for item in artifact["files"]:
        actual_hash = hashlib.sha256(expected_paths[item["path"]].read_bytes()).hexdigest()
        if actual_hash != item["sha256"]:
            raise SystemExit("Installer payload differs from staged artifact: " + item["path"])
    information = plistlib.loads((bundle / "Contents/Info.plist").read_bytes())
    distribution = ET.parse(expanded_dir / "Distribution")
    restart_required = any(reference.get("onConclusion") == "RequireRestart"
                           for reference in distribution.iter("pkg-ref"))
    if not restart_required:
        raise SystemExit("Product installer is missing its restart requirement.")
    package_hash = hashlib.sha256(product_path.read_bytes()).hexdigest()
    (product_path.with_suffix(".pkg.sha256")).write_text(package_hash + "  " + product_path.name + "\n")
    evidence_path = project_dir / "BuildReports/passed-stage1-20261111/RESULT.json"
    evidence = json.loads(evidence_path.read_text()) if evidence_path.exists() else None
    result = {
        "product": "Digits Driver", "version": information["CFBundleVersion"],
        "createdUTC": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "installer": product_path.name, "installerSHA256": package_hash,
        "packageIdentifier": "local.digits.driver.installer",
        "bundleIdentifier": information["CFBundleIdentifier"],
        "payloadMatchesStagedArtifacts": True, "restartRequired": restart_required,
        "contains": ["Digits Driver.kext", "digits-driver-ctl"],
        "signature": "unsigned experimental installer",
        "installedByPackaging": False,
        "driverKernelVersion": artifact["kernelVersion"],
        "baselinePhysicalReportEvidence": evidence,
        "candidatePhysicalReportGate": "not tested",
        "remainingGates": ["installer execution", "always-connected boot initialization", "updated Touch runtime", "Digits Tests"],
    }
    (project_dir / "BuildReports/DRIVER-RELEASE.json").write_text(json.dumps(result, indent=2) + "\n")
    print("Payload matches staged driver and helper; restart requirement present.")


if __name__ == "__main__":
    main()
