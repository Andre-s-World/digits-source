#!/usr/bin/env python3
"""Regenerate Digits Driver's controller table for the running macOS kernel.

Reads the active boot kernel collection as a file, rewrites
PinnedControllerTable.generated.hpp and moves every exact-kernel check in the
project to the new kernel. It stops without changing any source when the kernel's
USB controller no longer matches what the driver expects. It never installs,
loads or arms anything.
"""
import argparse
import json
from pathlib import Path
import subprocess

from KernelTable.FindActiveKernelCollection import find_active_kernel_collection
from KernelTable.RegenerateKernelTable import regenerate_kernel_table


if __name__ == "__main__":
    project = Path(__file__).resolve().parent.parent
    arguments = argparse.ArgumentParser(description=__doc__)
    arguments.add_argument("--collection", type=Path,
                           help="IMG4/IM4P kernel collection or decoded Mach-O; "
                                "defaults to the active boot collection")
    arguments.add_argument("--kernel-version",
                           help="Exact kernel version string; defaults to the running kernel")
    arguments.add_argument("--work", type=Path, default=project / ".build/KernelTable",
                           help="Where the decoded collection and table inputs are kept")
    arguments.add_argument("--check", action="store_true",
                           help="Confirm the committed table matches; change nothing")
    options = arguments.parse_args()
    collection = options.collection or find_active_kernel_collection()
    version = options.kernel_version or subprocess.run(
        ["/usr/sbin/sysctl", "-n", "kern.version"],
        check=True, capture_output=True, text=True).stdout.rstrip("\n")
    result = regenerate_kernel_table(project, collection, version, options.work, options.check)
    print(json.dumps(result, indent=2))
    if options.check:
        print("The committed table and kernel checks match this kernel.")
    elif result["changedChecks"]:
        print("Table regenerated. Rebuild Digits and run the installer again.")
    else:
        print("Table regenerated; the kernel checks already matched.")
