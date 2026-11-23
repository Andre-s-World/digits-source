#!/usr/bin/env python3
"""Wrap the reusable driver component with an explicit restart requirement."""
from pathlib import Path
import plistlib
import sys
import xml.etree.ElementTree as ET


def main():
    project_dir = Path(__file__).resolve().parent.parent
    information = plistlib.loads((project_dir / "DigitsDriver/Packaging/Driver/Digits Driver.kext/Contents/Info.plist").read_bytes())
    component_path = Path(sys.argv[1])
    distribution = ET.Element("installer-gui-script", {"minSpecVersion": "2"})
    ET.SubElement(distribution, "title").text = "Digits Driver " + information["CFBundleVersion"]
    ET.SubElement(distribution, "options", {"customize": "never", "require-scripts": "false"})
    ET.SubElement(distribution, "domains", {
        "enable_anywhere": "false", "enable_currentUserHome": "false", "enable_localSystem": "true",
    })
    ET.SubElement(distribution, "readme", {"file": "ReadMe.html", "mime-type": "text/html"})
    outline = ET.SubElement(distribution, "choices-outline")
    ET.SubElement(outline, "line", {"choice": "digits-driver"})
    choice = ET.SubElement(distribution, "choice", {
        "id": "digits-driver", "visible": "false", "title": "Digits Driver",
    })
    ET.SubElement(choice, "pkg-ref", {"id": "local.digits.driver.installer"})
    ET.SubElement(distribution, "pkg-ref", {
        "id": "local.digits.driver.installer", "version": information["CFBundleVersion"],
        "onConclusion": "RequireRestart",
    }).text = component_path.name
    ET.indent(distribution, space="    ")
    ET.ElementTree(distribution).write(sys.argv[2], encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    main()
