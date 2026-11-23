# Every exact-kernel check outside the generated table, and which values it holds.
# Each must keep exactly one copy so a partial update is never possible.
PINNED_FILES = {
    "DigitsDriver/Packaging/DriverInstaller/Scripts/preinstall.in": ("version",),
    "DigitsDriver/Packaging/DriverInstaller/Scripts/postinstall.in": ("version",),
    "DigitsInstaller/Backend/DigitsInstallerInternal.h": ("version",),
    "DigitsApp/Maintenance/Source/DigitsMaintenanceValidateInstalledDriver.m": ("version",),
    "Tools/update-display-binding.sh": ("version",),
    "Tools/stage-driver-artifacts.py": ("version", "sha256"),
    "DigitsDriver/verify-candidate.py": ("sha256",),
}


def retarget_kernel_pins(project, old_pins, new_pins, write):
    """Move every exact-kernel check from old_pins to new_pins, all or nothing.

    Pins are (kernel version, collection SHA-256). Every file is validated before any
    file is written. With write false, this only confirms each file holds old_pins.
    Returns the relative paths that changed.
    """
    values = {"version": (old_pins[0], new_pins[0]), "sha256": (old_pins[1], new_pins[1])}
    updates = {}
    for relative, kinds in PINNED_FILES.items():
        text = (project / relative).read_text()
        updated = text
        for kind in kinds:
            old, new = values[kind]
            if text.count(old) != 1:
                raise SystemExit(f"{relative} does not hold exactly one current kernel {kind}; "
                                 "fix it by hand before regenerating.")
            updated = updated.replace(old, new)
        if updated != text:
            updates[relative] = updated
    if write:
        for relative, updated in updates.items():
            (project / relative).write_text(updated)
    return sorted(updates)
