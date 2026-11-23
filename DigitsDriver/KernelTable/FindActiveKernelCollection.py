import plistlib
from pathlib import Path
import subprocess


def find_active_kernel_collection():
    """Return the boot kernel collection used by the running macOS installation.

    Apple silicon keeps it on the Preboot volume, under the root volume group's active
    boot hash. This is a plain file lookup; nothing is mounted, unlocked or changed.
    """
    disk = subprocess.run(["/usr/sbin/diskutil", "info", "-plist", "/"],
                          check=True, capture_output=True)
    group = plistlib.loads(disk.stdout).get("APFSVolumeGroupID")
    if not group:
        raise SystemExit("The root volume reports no APFS volume group.")
    boot = Path("/System/Volumes/Preboot") / group / "boot"
    active = (boot / "active").read_text().strip()
    collection = boot / active / "System/Library/Caches/com.apple.kernelcaches/kernelcache"
    if not collection.is_file():
        raise SystemExit(f"No boot kernel collection at {collection}")
    return collection
