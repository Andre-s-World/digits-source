#!/usr/bin/env python3
"""Keep the KEXT and DriverKit targets native after XcodeGen generation."""
from pathlib import Path
import re
import xml.etree.ElementTree as XML


def main():
    project_root = Path(__file__).resolve().parent.parent
    project_path = project_root / "Digits.xcodeproj/project.pbxproj"
    contents = project_path.read_text()
    contents, count = re.subn(
        r'(/\* Digits Driver \*/ = \{\n\s*isa = PBXNativeTarget;.*?productType = )"com\.apple\.product-type\.bundle";',
        r'\1"com.apple.product-type.kernel-extension";', contents, flags=re.S
    )
    if count != 1:
        raise SystemExit(f"Expected exactly one KEXT target, found {count}")
    contents = contents.replace("Digits Driver.bundle", "Digits Driver.kext")
    if "/* Digits Touch DEXT */ = {" in contents:
        contents, count = re.subn(
            r'(/\* Digits Touch DEXT \*/ = \{\n\s*isa = PBXNativeTarget;.*?productType = )"com\.apple\.product-type\.bundle";',
            r'\1"com.apple.product-type.driver-extension";', contents, flags=re.S
        )
        if count != 1:
            raise SystemExit(f"Expected exactly one DriverKit target, found {count}")
        contents = contents.replace("local.digits.touch.bundle", "local.digits.touch.dext")
        contents = contents.replace(
            'explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = local.digits.touch.dext;',
            'explicitFileType = "wrapper.driver-extension"; includeInIndex = 0; path = local.digits.touch.dext;'
        )
    project_path.write_text(contents)
    for scheme_path in (project_path.parent / "xcshareddata/xcschemes").glob("*.xcscheme"):
        scheme_path.write_text(scheme_path.read_text().replace("Digits Driver.bundle", "Digits Driver.kext").replace("local.digits.touch.bundle", "local.digits.touch.dext"))
        if scheme_path.stem != "Digits Driver":
            continue
        tree = XML.parse(scheme_path)
        for action_name in ("LaunchAction", "ProfileAction"):
            action = tree.getroot().find(action_name)
            if action is None:
                continue
            for runnable in list(action):
                if runnable.tag in ("BuildableProductRunnable", "PathRunnable"):
                    action.remove(runnable)
            XML.SubElement(action, "PathRunnable", {"runnableDebuggingMode": "0", "FilePath": "/usr/bin/true"})
        XML.indent(tree, space="   ")
        tree.write(scheme_path, encoding="UTF-8", xml_declaration=True)


if __name__ == "__main__":
    main()
