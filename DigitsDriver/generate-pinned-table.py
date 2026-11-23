#!/usr/bin/env python3
"""Generate immutable controller-table data from the pinned saved collection.

Offline only. This reads ordinary files; it does not query a running kernel,
load code, or access USB. Runtime code has no dependency on these input paths.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

PINNED_SHA256 = "d1003b5143ffd88439b4d45b6017f587171cfe6855660bed05370a2ea5db9fe9"
PINNED_UUID = "b2ca9932-beed-62e1-bc2b-0ee46b32c72d"
PINNED_CLASS = "__ZTV17AppleT8142USBXHCI"


def main():
    here = Path(__file__).resolve().parent
    workspace_probe = here.parent / "xeneon-probe"
    evidence = (workspace_probe if workspace_probe.is_dir()
                else here.parents[1] / "investigation")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=evidence / "custom-hook/apple-t8142-vtable-pac.json")
    parser.add_argument("--cache", type=Path, default=evidence / "kernelcache.decoded")
    parser.add_argument("--symbols", type=Path, default=evidence / "kernel-symbols.txt")
    parser.add_argument("--segments", type=Path, default=evidence / "kernel-segments.json")
    parser.add_argument("--output", type=Path, default=here / "PinnedControllerTable.generated.hpp")
    parser.add_argument("--check", action="store_true", help="Verify the generated file is current; do not write it")
    args = parser.parse_args()
    data = args.cache.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    manifest = json.loads(args.manifest.read_text())
    assert digest == PINNED_SHA256 == manifest["cache_sha256"], "Saved-image hash mismatch"
    assert manifest["collection_uuid"] == PINNED_UUID
    assert manifest["vtable_symbol"] == PINNED_CLASS
    assert manifest["structural_check_passed"] and not manifest["problems"]
    assert manifest["chain_covered_entries"] == 439
    assert manifest["pointer_formats"] == [8]
    symbols = {}
    for line in args.symbols.read_text().splitlines():
        fields = line.split()
        if len(fields) == 3:
            try:
                address = int(fields[0], 16)
            except ValueError:
                continue
            symbols.setdefault(fields[2], set()).add(address)

    def symbol(name):
        values = symbols.get(name, set())
        assert len(values) == 1, f"Nonunique or missing symbol {name}"
        return next(iter(values))

    segments = json.loads(args.segments.read_text())

    def file_offset(address):
        for _name, vmaddr, _vmsize, fileoff, filesize in segments:
            if vmaddr <= address < vmaddr + filesize:
                return fileoff + address - vmaddr
        raise AssertionError(f"Unmapped saved-image address {address:#x}")

    version_address = symbol("_version")
    offset = file_offset(version_address)
    version = data[offset:offset + 512].split(b"\0", 1)[0]
    assert version.startswith(b"Darwin Kernel Version 27.3.0:")
    assert 0 < len(version) < 511
    version = version.decode("ascii")
    anchor = symbol("__ZN15IOUSBHostDevice10gMetaClassE")
    table = int(manifest["vtable_address_unslid"], 16)
    end = int(manifest["candidate_bound_address_unslid"], 16)
    rows = manifest["entries"]
    assert table == symbol(PINNED_CLASS)
    assert end - table == len(rows) * 8 == (2 + 439 + 1) * 8
    for index, row in enumerate(rows):
        assert int(row["table_offset"], 16) == index * 8
        address = table + index * 8
        assert int(row["address_unslid"], 16) == address
        raw, = struct.unpack_from("<Q", data, file_offset(address))
        assert raw == int(row["raw_on_disk"], 16)
        if index < 2 or index == len(rows) - 1:
            assert not row["chain_covered"] and raw == 0
            continue
        assert row["chain_covered"] and row["is_auth"]
        assert row["key"] == 0 and row["address_diversity"]
        assert row["cache_level"] == 0 and row["target_segment"] == "__TEXT_EXEC"
        assert int(row["vptr_slot_offset"], 16) == (index - 2) * 8
        # Independently cross-check the fixed format8 bitfields against bytes.
        assert (raw >> 63) == 1 and ((raw >> 49) & 3) == 0
        assert ((raw >> 48) & 1) == 1 and ((raw >> 30) & 3) == 0
        assert ((raw >> 32) & 0xffff) == int(row["diversity"], 16)
        assert (raw & 0x3fffffff) + int(manifest["collection_preferred_base"], 16) == int(row["target_unslid"], 16)
    entries = rows[2:-1]
    outer = entries[0x948 // 8]
    inner = entries[0x958 // 8]
    assert int(outer["diversity"], 16) == 0x8346
    assert int(inner["diversity"], 16) == 0x0327
    assert int(outer["target_unslid"], 16) == symbol("__ZN12AppleUSBXHCI12createDeviceE31tInternalUSBHostConnectionSpeedjj")
    assert int(inner["target_unslid"], 16) == symbol("__ZN15AppleUSBXHCIARM21createIOUSBHostDeviceE31tInternalUSBHostConnectionSpeedtj")
    lines = [
        "// Generated offline by generate-pinned-table.py. Do not hand edit.",
        "#pragma once", "#include <stddef.h>", "#include <stdint.h>",
        "namespace XeneonPinnedController { namespace Data {",
        f'constexpr char kImageSHA256[] = "{digest}";',
        f'constexpr char kCollectionUUID[] = "{PINNED_UUID}";',
        f"constexpr char kKernelVersion[] = {json.dumps(version)};",
        f"constexpr uintptr_t kVersionUnslid = UINT64_C({version_address:#x});",
        f"constexpr uintptr_t kAnchorUnslid = UINT64_C({anchor:#x});",
        f"constexpr uintptr_t kTableUnslid = UINT64_C({table:#x});",
        "constexpr size_t kFunctionCount = 439;",
        "constexpr size_t kHeaderWords = 2;",
        "constexpr size_t kTableWords = kHeaderWords + kFunctionCount + 1;",
        "constexpr size_t kTableBytes = kTableWords * sizeof(uintptr_t);",
        "constexpr size_t kOuterIndex = 0x948 / sizeof(uintptr_t);",
        "constexpr size_t kInnerIndex = 0x958 / sizeof(uintptr_t);",
        "struct Entry { uintptr_t targetUnslid; uint16_t diversity; };",
        "constexpr Entry kEntries[kFunctionCount] = {",
    ]
    for row in entries:
        lines.append(f'    {{UINT64_C({int(row["target_unslid"], 16):#x}), UINT16_C({int(row["diversity"], 16):#x})}}, // slot {row["vptr_slot_offset"]}')
    lines += ["};", "} } // namespace XeneonPinnedController::Data", ""]
    encoded = "\n".join(lines)
    if args.check:
        assert args.output.read_text() == encoded, "Generated table is stale"
    else:
        args.output.write_text(encoded)
    print(json.dumps({"output": str(args.output), "mode": "check" if args.check else "generate", "image_sha256": digest, "collection_uuid": PINNED_UUID, "version": version, "anchor_unslid": hex(anchor), "functions": len(entries), "table_bytes": end - table}))


if __name__ == "__main__":
    main()
