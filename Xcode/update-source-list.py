#!/usr/bin/env python3
"""Keep Xcode and the standalone KEXT build on the same explicit source list."""
import json
from pathlib import Path


def main():
    project_root = Path(__file__).resolve().parent.parent
    specification_path = project_root / "project.json"
    specification = json.loads(specification_path.read_text())
    driver_root = project_root / "DigitsDriver"
    sources = []
    for line in (driver_root / "kernel-sources.txt").read_text().splitlines():
        if line.strip():
            source = driver_root / line.strip()
            if not source.is_file():
                raise SystemExit(f"Missing active KEXT source: {source}")
            sources.append({"path": str(source.relative_to(project_root))})
    for header in sorted(driver_root.glob("*.hpp")):
        sources.append({"path": str(header.relative_to(project_root)), "buildPhase": "none"})
    sources.append({"path": "DigitsDriver/sdk27-pm-types-compile-only.h", "buildPhase": "none"})
    specification["targets"]["Digits Driver"]["sources"] = sources
    specification["fileGroups"] = ["Testing", "Tools", "DigitsDriver/Packaging", "README.md"]
    specification_path.write_text(json.dumps(specification, indent=2) + "\n")


if __name__ == "__main__":
    main()
