#!/usr/bin/env python3
"""Generate immutable controller-table data from a saved kernel collection.

Offline only. This reads ordinary files; it does not query a running kernel,
load code, or access USB. Runtime code has no dependency on these input paths.
The inputs are written by regenerate-kernel-table.py.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

PINNED_CLASS = "__ZTV17AppleT8142USBXHCI"

# Controller vtable layouts reviewed against the factory hooks, keyed by the SHA-256
# of the ordered slot diversities. A diversity identifies the declared method, so new
# overrides keep a layout while added, removed or reordered methods change it. Each
# layout was compared with the tested one: both factories, the IOUSBHostDevice vtable
# and creation path, and the string-descriptor request path are unchanged.
REVIEWED_LAYOUTS = {
    # macOS 27.3, Darwin 27.3.0 built October 30, 2026. Tested on hardware.
    "9906d11e524df201ed15fb84fed0d8fd9d58eb34f1b054bc00feed7037d3c997": 439,
    # macOS 27.3, Darwin 27.3.0 built November 9, 2026: inserts
    # AppleUSBXHCIARM::dartErrorHandler at slot 0xd98; the last four methods move down.
    "16bcd215d904aa612071d2e0e5a3a5af52a014aacdb7b1ad72d786b98a0d842d": 440,
}


def main():
    here = Path(__file__).resolve().parent
    work = here.parent / ".build/KernelTable"
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=work / "apple-t8142-vtable-pac.json")
    parser.add_argument("--cache", type=Path, default=work / "kernelcache.decoded")
    parser.add_argument("--symbols", type=Path, default=work / "kernel-symbols.txt")
    parser.add_argument("--segments", type=Path, default=work / "kernel-segments.json")
    parser.add_argument("--kernel-version", help="Require the collection to be exactly this kernel")
    parser.add_argument("--output", type=Path, default=here / "PinnedControllerTable.generated.hpp")
    parser.add_argument("--check", action="store_true", help="Verify the generated file is current; do not write it")
    args = parser.parse_args()
    data = args.cache.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    manifest = json.loads(args.manifest.read_text())
    assert digest == manifest["cache_sha256"], "Saved-image hash mismatch"
    collection_uuid = manifest["collection_uuid"]
    assert manifest["vtable_symbol"] == PINNED_CLASS
    assert manifest["structural_check_passed"] and not manifest["problems"]
    function_count = manifest["chain_covered_entries"]
    layout = hashlib.sha256(",".join(
        row["diversity"] for row in manifest["entries"] if row["chain_covered"]).encode()).hexdigest()
    assert REVIEWED_LAYOUTS.get(layout) == function_count, (
        f"AppleT8142USBXHCI has an unreviewed layout ({function_count} virtual functions, "
        f"layout {layout}); review it against the factory hooks before adding it to REVIEWED_LAYOUTS")
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
    assert version.startswith(b"Darwin Kernel Version ")
    assert 0 < len(version) < 511
    version = version.decode("ascii")
    assert args.kernel_version is None or version == args.kernel_version, "Collection is for a different kernel"
    anchor = symbol("__ZN15IOUSBHostDevice10gMetaClassE")
    table = int(manifest["vtable_address_unslid"], 16)
    end = int(manifest["candidate_bound_address_unslid"], 16)
    rows = manifest["entries"]
    assert table == symbol(PINNED_CLASS)
    assert end - table == len(rows) * 8 == (2 + function_count + 1) * 8
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
    factory_message = "The controller's device factory slots moved; Digits Driver hooks 0x948 and 0x958"
    assert int(outer["diversity"], 16) == 0x8346, factory_message
    assert int(inner["diversity"], 16) == 0x0327, factory_message
    assert int(outer["target_unslid"], 16) == symbol("__ZN12AppleUSBXHCI12createDeviceE31tInternalUSBHostConnectionSpeedjj"), factory_message
    assert int(inner["target_unslid"], 16) == symbol("__ZN15AppleUSBXHCIARM21createIOUSBHostDeviceE31tInternalUSBHostConnectionSpeedtj"), factory_message
    lines = [
        "// Generated offline by generate-pinned-table.py. Do not hand edit.",
        "#pragma once", "#include <stddef.h>", "#include <stdint.h>",
        "namespace XeneonPinnedController { namespace Data {",
        f'constexpr char kImageSHA256[] = "{digest}";',
        f'constexpr char kCollectionUUID[] = "{collection_uuid}";',
        f"constexpr char kKernelVersion[] = {json.dumps(version)};",
        f"constexpr uintptr_t kVersionUnslid = UINT64_C({version_address:#x});",
        f"constexpr uintptr_t kAnchorUnslid = UINT64_C({anchor:#x});",
        f"constexpr uintptr_t kTableUnslid = UINT64_C({table:#x});",
        f"constexpr size_t kFunctionCount = {function_count};",
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
    print(json.dumps({"output": str(args.output), "mode": "check" if args.check else "generate", "image_sha256": digest, "collection_uuid": collection_uuid, "version": version, "anchor_unslid": hex(anchor), "functions": len(entries), "table_bytes": end - table}))


if __name__ == "__main__":
    main()
