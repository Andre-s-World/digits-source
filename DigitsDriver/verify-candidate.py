#!/usr/bin/env python3
"""Inspect a candidate kext and saved kernel collection as files only.

Never installs, loads, signs, invokes a binary, or accesses hardware. A passing
report covers the named static checks; it is not runtime safety qualification.
"""

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import plistlib
import struct
import sys
import uuid


class MachO:
    def __init__(self, data, base=0):
        self.data, self.base = data, base
        if base < 0 or base + 32 > len(data):
            raise ValueError("Truncated Mach-O header")
        h = struct.unpack_from("<8I", data, base)
        if h[0] != 0xFEEDFACF:
            raise ValueError("Expected little-endian 64-bit Mach-O")
        self.cpu, self.subtype, self.kind = h[1:4]
        self.commands, self.segments, self.sections = [], [], []
        self.symtab, self.uuid = None, None
        p, limit = base + 32, base + 32 + h[5]
        if limit > len(data):
            raise ValueError("Truncated load commands")
        for _ in range(h[4]):
            if p + 8 > limit:
                raise ValueError("Truncated load command")
            cmd, size = struct.unpack_from("<II", data, p)
            if size < 8 or size % 8 or p + size > limit:
                raise ValueError("Invalid load-command size")
            self.commands.append((cmd, p, size))
            if cmd == 0x19:
                if size < 72:
                    raise ValueError("Truncated segment")
                name = data[p + 8:p + 24].split(b"\0")[0].decode()
                vm, vs, off, fs, maxprot, initprot, count, _ = (
                    struct.unpack_from("<4Q4I", data, p + 24))
                if size < 72 + 80 * count or off + fs > len(data):
                    raise ValueError("Invalid segment or section bounds")
                self.segments.append({"name": name, "address": vm,
                                      "vmsize": vs, "fileoff": off,
                                      "filesize": fs, "maxprot": maxprot,
                                      "initprot": initprot})
                for i in range(count):
                    q = p + 72 + 80 * i
                    sn, sg, a, length, so = struct.unpack_from("<16s16sQQI", data, q)
                    self.sections.append({"segment": sg.rstrip(b"\0").decode(),
                                          "name": sn.rstrip(b"\0").decode(),
                                          "address": a, "size": length,
                                          "fileoff": so})
            elif cmd == 2:
                if size != 24:
                    raise ValueError("Invalid symbol-table command")
                self.symtab = struct.unpack_from("<4I", data, p + 8)
            elif cmd == 0x1B:
                if size != 24:
                    raise ValueError("Invalid UUID command")
                self.uuid = str(uuid.UUID(bytes=data[p + 8:p + 24]))
            p += size
        if p != limit:
            raise ValueError("Load-command count/size mismatch")

    def symbols(self):
        if self.symtab is None:
            raise ValueError("Missing symbol table")
        off, count, strings, length = self.symtab
        if off + count * 16 > len(self.data) or strings + length > len(self.data):
            raise ValueError("Truncated symbol or string table")
        for i in range(count):
            q = off + i * 16
            no, typ, sec, desc, value = struct.unpack_from("<IBBHQ", self.data, q)
            if no >= length:
                raise ValueError("Invalid symbol string index")
            end = self.data.find(b"\0", strings + no, strings + length)
            if end < 0:
                raise ValueError("Unterminated symbol name")
            name = self.data[strings + no:end].decode()
            if name:
                yield {"name": name, "n_type": typ, "n_sect": sec,
                       "n_desc": desc, "value": value, "nlist_fileoff": q}

    def bytes_at(self, address, size):
        for s in self.segments:
            if s["address"] <= address and address + size <= s["address"] + s["filesize"]:
                off = s["fileoff"] + address - s["address"]
                return self.data[off:off + size]
        raise ValueError("Address is not backed by Mach-O file bytes")

    def section(self, segment, name):
        return next(s for s in self.sections
                    if s["segment"] == segment and s["name"] == name)

    def chained_pointers(self):
        """Decode linked arm64e kernel chains without applying any fixups.

        Format and stride follow the installed SDK mach-o/fixup-chains.h.
        Unknown formats and malformed chains fail closed rather than silently
        treating encoded pointer words as resolved addresses.
        """
        commands = [p for c, p, _ in self.commands if c == 0x80000034]
        if len(commands) != 1:
            raise ValueError("Expected exactly one chained-fixups command")
        off, size = struct.unpack_from("<II", self.data, commands[0] + 8)
        if off + size > len(self.data) or size < 28:
            raise ValueError("Invalid chained-fixups bounds")
        blob = self.data[off:off + size]
        version, starts, _, _, _, _, _ = struct.unpack_from("<7I", blob)
        if version != 0 or starts + 4 > size:
            raise ValueError("Unsupported chained-fixups header")
        count, = struct.unpack_from("<I", blob, starts)
        if count != len(self.segments) or starts + 4 + 4 * count > size:
            raise ValueError("Invalid chained segment count")
        base = min(s["address"] for s in self.segments if s["filesize"])
        pointers = {}
        for index, segment in enumerate(self.segments):
            relative, = struct.unpack_from("<I", blob, starts + 4 + index * 4)
            if relative == 0:
                continue
            q = starts + relative
            if q + 22 > size:
                raise ValueError("Truncated chained segment starts")
            length, page_size, fmt, segment_offset, _, pages = struct.unpack_from("<IHHQIH", blob, q)
            if (length < 22 + 2 * pages or q + length > size or
                    page_size not in (0x1000, 0x4000) or fmt != 7 or
                    segment_offset != segment["address"] - base):
                raise ValueError("Unsupported or malformed arm64e kernel starts")
            entries = list(struct.unpack_from("<" + "H" * ((length - 22) // 2), blob, q + 22))
            for page, first in enumerate(entries[:pages]):
                if first == 0xFFFF:
                    continue
                chain_starts = []
                if first & 0x8000:
                    at = first & 0x7FFF
                    while True:
                        if at >= len(entries):
                            raise ValueError("Invalid chained multi-start index")
                        entry = entries[at]
                        chain_starts.append(entry & 0x7FFF)
                        at += 1
                        if entry & 0x8000:
                            break
                else:
                    chain_starts.append(first)
                for start in chain_starts:
                    cursor = start
                    while True:
                        if cursor % 4 or cursor + 8 > page_size:
                            raise ValueError("Chained pointer crosses its page")
                        address = segment["address"] + page * page_size + cursor
                        if address in pointers:
                            raise ValueError("Duplicate or cyclic chained pointer")
                        raw, = struct.unpack("<Q", self.bytes_at(address, 8))
                        auth, bind = bool(raw >> 63), bool(raw >> 62 & 1)
                        row = {"address": address, "raw": hex(raw), "auth": auth, "bind": bind,
                               "pointer_format": fmt, "chain_covered": True}
                        if auth:
                            row.update(diversity=raw >> 32 & 0xFFFF,
                                       address_diversity=bool(raw >> 48 & 1), key=raw >> 49 & 3)
                            if bind:
                                if raw >> 16 & 0xFFFF:
                                    raise ValueError("Authenticated bind has nonzero reserved bits")
                                row["ordinal"] = raw & 0xFFFF
                            else:
                                row["target"] = base + (raw & 0xFFFFFFFF)
                        elif not bind:
                            row["target"] = base + ((raw & ((1 << 43) - 1)) | ((raw >> 43 & 0xFF) << 56))
                        else:
                            row["ordinal"] = raw & 0xFFFF
                        pointers[address] = row
                        step = raw >> 51 & 0x7FF
                        if step == 0:
                            break
                        cursor += 4 * step
        return pointers


def kmod_wiring(candidate, defined, pointers, start_symbol, stop_symbol):
    """Verify SDK libkmod wrapper registration and authenticated entry cells.

    No instructions are executed. The wrapper check deliberately accepts only
    the SDK's measured short tail-call shape, including its 0xe4fe ABI tag.
    A changed SDK wrapper requires review instead of optimistic matching.
    """
    rows, checks = {}, {}

    def pointer(label, address, target):
        row = pointers.get(address)
        rows[label] = row
        checks[label] = bool(row and row.get("auth") and not row.get("bind") and
                             row.get("key") == 0 and not row.get("address_diversity") and
                             row.get("diversity") == 0xE4FE and row.get("target") == target)

    required = ("_kmod_info", "__realmain", "__antimain", "__start", "__stop", start_symbol, stop_symbol)
    if not all(s in defined for s in required):
        return {"required_entry_symbols": False}, rows
    checks["required_entry_symbols"] = True
    pointer("realmain_calls_named_start", defined["__realmain"]["value"], defined[start_symbol]["value"])
    pointer("antimain_calls_named_stop", defined["__antimain"]["value"], defined[stop_symbol]["value"])
    # mach/kmod.h uses #pragma pack(4): 180/188 are the arm64 start/stop offsets.
    pointer("kmod_registered_start_wrapper", defined["_kmod_info"]["value"] + 180, defined["__start"]["value"])
    pointer("kmod_registered_stop_wrapper", defined["_kmod_info"]["value"] + 188, defined["__stop"]["value"])
    for wrapper, cell in (("__start", "__realmain"), ("__stop", "__antimain")):
        address = defined[wrapper]["value"]
        words = struct.unpack("<9I", candidate.bytes_at(address, 36))
        adrp, add = words[1:3]
        # bti c; adrp x8; add x8,x8; ldr x16,[x8]; cbz x16,+12;
        # mov x17,#0xe4fe; braa x16,x17; mov w0,#0; ret.
        fixed = words[0] == 0xD503245F and words[3:] == (
            0xF9400110, 0xB4000070, 0xD29C9FD1, 0xD71F0A11, 0x52800000, 0xD65F03C0)
        valid_adrp = adrp & 0x9F00001F == 0x90000008
        valid_add = add & 0xFFC003FF == 0x91000108
        immediate = ((adrp >> 5 & 0x7FFFF) << 2) | (adrp >> 29 & 3)
        if immediate & (1 << 20):
            immediate -= 1 << 21
        page = ((address + 4) & ~0xFFF) + (immediate << 12)
        resolved = page + (add >> 10 & 0xFFF)
        checks[wrapper + "_sdk_tail_call_to_cell"] = bool(
            fixed and valid_adrp and valid_add and resolved == defined[cell]["value"])
    return checks, rows


def verify(args):
    bundle = args.bundle.resolve()
    info = plistlib.loads((bundle / "Contents/Info.plist").read_bytes())
    executable = info["CFBundleExecutable"]
    if not isinstance(executable, str) or Path(executable).name != executable:
        raise ValueError("Invalid CFBundleExecutable basename")
    binary = bundle / "Contents/MacOS" / executable
    binary_data = binary.read_bytes()
    candidate = MachO(binary_data)
    checks = {}

    def require(name, value):
        checks[name] = bool(value)

    require("arm64e_kernel_abi", candidate.cpu == 0x0100000C and
            candidate.subtype & 0xFFFFFF == 2 and candidate.subtype >> 24 == 0xC0)
    require("kext_bundle_format", candidate.kind == 0xB and info.get("CFBundlePackageType") == "KEXT")
    require("digits_driver_product_identity",
            info.get("CFBundleIdentifier") == "local.digits.driver" and
            info.get("CFBundleName") == "Digits Driver" and
            executable == "DigitsDriver" and info.get("CFBundleVersion") == "0.2.1")
    require("no_executable_entry_commands", not any(c in (0x80000028, 0x5) for c, _, _ in candidate.commands))
    require("no_initial_rwx_segments", not any(s["initprot"] & 7 == 7 for s in candidate.segments))
    require("unsigned_expected", not any(c == 0x1D for c, _, _ in candidate.commands))
    require("no_matching_personalities", not info.get("IOKitPersonalities"))
    symbols = list(candidate.symbols())
    # STABS debug globals can share a name with a real definition and have low
    # type bits zero. They are not Mach-O undefined symbols or import requests.
    external_symbols = [s for s in symbols if not s["n_type"] & 0xE0]
    defined = {s["name"]: s for s in external_symbols if s["n_type"] & 0xE == 0xE}
    imports = sorted({s["name"] for s in external_symbols if s["n_type"] & 0xE == 0})
    require("synchronous_request_override_defined",
            "__ZN18XeneonStringDevice13deviceRequestEP9IOServiceRN11StandardUSB13DeviceRequestEPvRjj"
            in defined)
    require("complete_native_device_identity_snapshot_defined",
            "__ZN20DigitsStringRequests33snapshotCompletedDeviceDescriptorEPKhjjb" in defined)
    require("old_authored_string_getter_removed",
            not any(name.startswith("__ZN18XeneonStringDevice19getStringDescriptor") or
                    name.startswith("__ZN18XeneonStringDevice14readString") or
                    name.startswith("__ZN18XeneonStringDevice15readString")
                    for name in defined))
    require("self_retain_api_imported", "_OSKextRetainKextWithLoadTag" in imports)
    for name in args.require_symbol:
        require("required_symbol:" + name, name in defined)
    stop = defined.get(args.stop_symbol)
    require("named_stop_defined", stop is not None)
    # Accept the exact optimized leaf or this build's -O0 stack-only leaf. The
    # latter saves argument registers to its own 16-byte stack frame, makes no
    # calls, restores SP, and returns KERN_FAILURE without any unhooking path.
    stop_bytes = candidate.bytes_at(stop["value"], 8) if stop else b""
    if stop_bytes.startswith(bytes.fromhex("5f2403d5")):
        stop_bytes = candidate.bytes_at(stop["value"], 28)
        if stop_bytes[4:12] == bytes.fromhex("a0008052c0035fd6"):
            stop_bytes = stop_bytes[:12]
    require("stop_is_leaf_kern_failure", stop_bytes in (
        bytes.fromhex("a0008052c0035fd6"), bytes.fromhex("5f2403d5a0008052c0035fd6"),
        bytes.fromhex("5f2403d5ff4300d1e00700f9e10300f9a0008052ff430091c0035fd6")))
    pointers = candidate.chained_pointers()
    request_override = defined.get(
        "__ZN18XeneonStringDevice13deviceRequestEP9IOServiceRN11StandardUSB13DeviceRequestEPvRjj")
    device_vtable = defined.get("__ZTV18XeneonStringDevice")
    request_slot = pointers.get(device_vtable["value"] + 16 + 0xB68) if device_vtable else None
    require("native_sync_request_slot_and_pac",
            bool(request_override and request_slot and request_slot.get("auth") and
                 not request_slot.get("bind") and request_slot.get("key") == 0 and
                 request_slot.get("address_diversity") and
                 request_slot.get("diversity") == 0x4AEB and
                 request_slot.get("target") == request_override["value"]))
    wiring_checks, wiring_rows = kmod_wiring(candidate, defined, pointers, args.start_symbol, args.stop_symbol)
    for name, result in wiring_checks.items():
        require("kmod_pac:" + name, result)

    cache_data = args.kernel_cache.read_bytes()
    require("pinned_kernel_cache_hash", hashlib.sha256(cache_data).hexdigest() == args.kernel_sha256)
    collection = MachO(cache_data)
    kernel, providers = None, defaultdict(list)
    imports_set = set(imports)
    for cmd, p, size in collection.commands:
        if cmd != 0x80000035:
            continue
        _, off, no, _ = struct.unpack_from("<QQII", cache_data, p + 8)
        if no >= size:
            raise ValueError("Invalid fileset name offset")
        provider = cache_data[p + no:p + size].split(b"\0")[0].decode()
        image = MachO(cache_data, off)
        if provider == "com.apple.kernel":
            kernel = image
        if image.symtab is None:
            continue
        for s in image.symbols():
            if s["name"] in imports_set and s["n_type"] & 0xE == 0xE:
                providers[s["name"]].append(dict(s, provider=provider))
    if kernel is None:
        raise ValueError("Kernel image missing from fileset")
    sec = kernel.section("__LINKINFO", "__symbolsets")
    sets = plistlib.loads(cache_data[sec["fileoff"]:sec["fileoff"] + sec["size"]])
    kpis = defaultdict(list)
    for group in sets["SymbolsSets"]:
        for entry in group["Symbols"]:
            for name in imports:
                if entry.get("SymbolName") == name or ("SymbolPrefix" in entry and name.startswith(entry["SymbolPrefix"])):
                    kpis[name].append(group["CFBundleIdentifier"])
    deps = info.get("OSBundleLibraries", {})
    rows = []
    for name in imports:
        matches = providers[name]
        covered = [p for p in matches if
                   (p["provider"] in deps or p["provider"] == "com.apple.kernel" and any(k in deps for k in kpis[name]))
                   and p["n_type"] & 1 and not p["n_type"] & 0x10]
        rows.append({"name": name, "definitions": matches,
                     "kernel_symbolsets": kpis[name], "declared_external_provider_match": bool(covered)})
    require("all_imports_have_declared_external_providers", all(r["declared_external_provider_match"] for r in rows))
    return {"schema": "xeneon-static-candidate-verification-v2",
            "offline_only": True, "installed": False, "loaded": False,
            "runtime_safety_proven": False, "bundle": str(bundle),
            "binary_sha256": hashlib.sha256(binary_data).hexdigest(),
            "kernel_sha256": hashlib.sha256(cache_data).hexdigest(),
            "kernel_uuid": collection.uuid, "checks": checks,
            "static_checks_passed": all(checks.values()),
            "stop_symbol": args.stop_symbol, "stop_bytes_hex": stop_bytes.hex(),
            "start_symbol": args.start_symbol,
            "kmod_authenticated_pointer_wiring": wiring_rows,
            "chained_pointer_count": len(pointers),
            "authenticated_pointer_schemas": [dict(auth=schema[0], bind=schema[1],
                 key=schema[2], address_diversity=schema[3], diversity=schema[4], count=count)
                 for schema, count in sorted(Counter((p["auth"], p["bind"], p.get("key", -1),
                     p.get("address_diversity", False), p.get("diversity", -1)) for p in pointers.values()).items())],
            "undefined_symbols": len(imports), "imports": rows,
            "cpp_initializer_sections": [s for s in candidate.sections if s["name"] == "__mod_init_func"],
            "limits": ["Self-retain execution/order and source lifetime invariants require separate review.",
                       "Import eligibility does not prove OSKext acceptance or ABI/PAC compatibility.",
                       "No live publication, enumeration, USB reports, or touch behavior is tested."]}


def self_test():
    good = struct.pack("<8I", 0xFEEDFACF, 0x0100000C, 0xC0000002, 0xB, 0, 0, 0, 0)
    assert MachO(good).kind == 0xB
    bad = [b"", good[:31], good[:16] + struct.pack("<II", 1, 8) + good[24:] + struct.pack("<II", 0x19, 0),
           good[:16] + struct.pack("<II", 1, 16) + good[24:] + struct.pack("<II", 0x19, 72)]
    for payload in bad:
        try:
            MachO(payload)
        except (ValueError, struct.error):
            continue
        raise AssertionError("Malformed Mach-O was accepted")
    fixture = bytearray(0x2000)
    struct.pack_into("<8I", fixture, 0, 0xFEEDFACF, 0x0100000C, 0xC0000002, 0xB, 2, 88, 0, 0)
    struct.pack_into("<II16s4Q4I", fixture, 32, 0x19, 72, b"__TEXT", 0, 0x2000, 0, 0x2000, 7, 5, 0, 0)
    struct.pack_into("<4I", fixture, 104, 0x80000034, 16, 0x1800, 64)
    struct.pack_into("<7I", fixture, 0x1800, 0, 32, 64, 64, 0, 1, 0)
    struct.pack_into("<II", fixture, 0x1820, 1, 8)
    struct.pack_into("<IHHQIHH", fixture, 0x1828, 24, 4096, 7, 0, 0, 1, 0x100)
    struct.pack_into("<Q", fixture, 0x100, (1 << 63) | (0xE4FE << 32) | 0x1000)
    decoded = MachO(fixture).chained_pointers()
    assert decoded[0x100]["target"] == 0x1000
    assert decoded[0x100]["diversity"] == 0xE4FE
    malformed_chains = []
    for position, fmt, value in ((0x182E, "H", 8),  # Unknown pointer format.
                                  (0x183E, "H", 0xFFF),  # Pointer crosses page.
                                  (0x100, "Q", (1 << 63) | (0x7FF << 51)),  # Next exits page.
                                  (0x183E, "H", 0x800F)):  # Multi-start index outside record.
        broken = bytearray(fixture)
        struct.pack_into("<" + fmt, broken, position, value)
        malformed_chains.append(broken)
    for payload in malformed_chains:
        try:
            MachO(payload).chained_pointers()
        except (ValueError, struct.error):
            continue
        raise AssertionError("Malformed chain was accepted")
    print("PASS: minimal Mach-O, authenticated chain, four invalid headers and four invalid chains")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("bundle", type=Path, nargs="?")
    p.add_argument("--stop-symbol")
    p.add_argument("--start-symbol", default="_XeneonEarlyInitStart")
    p.add_argument("--require-symbol", action="append", default=[])
    p.add_argument("--kernel-cache", type=Path, default=Path(__file__).resolve().parent.parent / ".build/KernelTable/kernelcache.decoded")
    p.add_argument("--kernel-sha256", default="d1003b5143ffd88439b4d45b6017f587171cfe6855660bed05370a2ea5db9fe9")
    p.add_argument("--output", type=Path)
    p.add_argument("--self-test", action="store_true")
    args = p.parse_args()
    if args.self_test:
        self_test()
        return
    if args.bundle is None or args.stop_symbol is None:
        p.error("bundle and --stop-symbol are required unless --self-test")
    result = verify(args)
    encoded = json.dumps(result, indent=2) + "\n"
    if args.output:
        args.output.write_text(encoded)
    print(json.dumps({k: v for k, v in result.items() if k not in ("imports", "cpp_initializer_sections")}, indent=2))
    if not result["static_checks_passed"]:
        sys.exit(1)


if __name__ == "__main__":
    main()
