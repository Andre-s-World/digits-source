#!/usr/bin/env python3
"""Prepare this Mac's optional binding separately from every installer payload."""
import hashlib
from pathlib import Path
import plistlib
import sys


def main():
    if len(sys.argv) != 4:
        raise SystemExit("Usage: prepare-system-binding.py USER_BINDING DISPLAY_SNAPSHOT OUTPUT")
    binding = plistlib.loads(Path(sys.argv[1]).read_bytes())
    services = plistlib.loads(Path(sys.argv[2]).read_bytes())
    matches = []
    for service in services:
        descriptor = service.get("IODisplayEDID", service.get("EDID"))
        if not service.get("Active") or not isinstance(descriptor, bytes) or len(descriptor) < 128:
            continue
        if descriptor[:8] != bytes.fromhex("00ffffffffffff00") or sum(descriptor[:128]) % 256:
            continue
        vendor = int.from_bytes(descriptor[8:10], "big")
        product = int.from_bytes(descriptor[10:12], "little")
        if (vendor, product) == (0x0e58, 0xed00):
            matches.append(descriptor)
    if len(matches) != 1:
        raise SystemExit("Expected exactly one active, validated physical Edge display.")
    descriptor = matches[0]
    binding.update(DisplayVendorID=0x0e58, DisplayProductID=0xed00,
                   DisplaySerialNumber=int.from_bytes(descriptor[12:16], "little"),
                   DisplayEDIDSHA256=hashlib.sha256(descriptor).hexdigest())
    output = Path(sys.argv[3])
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("xb") as stream:
        plistlib.dump(binding, stream)
    print("Prepared optional local binding: " + str(output))
    print("Nothing installed. This file is excluded from installer payloads.")


if __name__ == "__main__":
    main()
