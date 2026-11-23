import hashlib
import struct
import uuid

from .FileOffsetForAddress import file_offset_for_address

LC_UUID = 0x1B
LC_DYLD_CHAINED_FIXUPS = 0x80000034


def decode_vtable_pac(collection, segments, symbol_rows, vtable_symbols, cache_path):
    """Decode the signed (PAC) records of the named vtables in a kernel collection.

    Each table is bounded by the next defined vtable symbol. Every fixup chain in the
    collection is walked, so each retained word is proven to be a fixup rather than
    arbitrary bits. A table passes the structural check only when all its non-header
    words are chain-covered, authenticated __TEXT_EXEC pointers or zero padding.
    Returns {vtable symbol: manifest} in the form generate-pinned-table.py reads.
    """
    fixups, collection_uuid, offset = None, None, 32
    for _ in range(struct.unpack_from("<I", collection, 16)[0]):
        command, size = struct.unpack_from("<II", collection, offset)
        if command == LC_DYLD_CHAINED_FIXUPS:
            fixups = struct.unpack_from("<II", collection, offset + 8)
        elif command == LC_UUID:
            collection_uuid = str(uuid.UUID(bytes=collection[offset + 8:offset + 24]))
        offset += size
    if not fixups:
        raise ValueError("No collection-level LC_DYLD_CHAINED_FIXUPS")
    base = next(segment[1] for segment in segments if segment[0] == "__TEXT")

    def segment_name(address):
        for name, vmaddr, vmsize, _, _ in segments:
            if vmaddr <= address < vmaddr + vmsize:
                return name
        return None

    symbols, vtables = {}, {}
    for _entry, address, _kind, name in symbol_rows:
        symbols.setdefault(address, set()).add(name)
        if name.startswith("__ZTV"):
            vtables.setdefault(address, set()).add(name)
    ranges = {}
    for vtable_symbol in vtable_symbols:
        starts = [address for address, names in vtables.items() if vtable_symbol in names]
        if len(starts) != 1:
            raise ValueError(f"Expected one vtable symbol {vtable_symbol}")
        table_end = min(address for address in vtables if address > starts[0])
        if table_end - starts[0] > 0x10000:
            raise ValueError(f"Next vtable after {vtable_symbol} is implausibly far away")
        ranges[vtable_symbol] = (starts[0], table_end)

    fixoff, fixsize = fixups
    if fixoff + fixsize > len(collection):
        raise ValueError("Truncated chained-fixups payload")
    if struct.unpack_from("<7I", collection, fixoff)[0] != 0:
        raise ValueError("Unsupported fixups version")
    starts = fixoff + struct.unpack_from("<7I", collection, fixoff)[1]
    records, chain_count, visited_count, formats = {}, 0, 0, set()
    for index in range(struct.unpack_from("<I", collection, starts)[0]):
        relative = struct.unpack_from("<I", collection, starts + 4 + 4 * index)[0]
        if not relative:
            continue
        position = starts + relative
        _size, page_size, pointer_format, segment_offset, _, page_count = (
            struct.unpack_from("<IHHQIH", collection, position))
        if pointer_format != 8:
            raise ValueError(f"Unsupported pointer format {pointer_format}")
        formats.add(pointer_format)
        for page in range(page_count):
            page_start = struct.unpack_from("<H", collection, position + 22 + 2 * page)[0]
            if page_start == 0xFFFF:
                continue
            if page_start & 0x8000:
                raise ValueError("Multiple chain starts not supported")
            address = base + segment_offset + page * page_size + page_start
            page_end = base + segment_offset + (page + 1) * page_size
            chain_count += 1
            while True:
                # Format 8 uses a 4-byte stride, so a 64-bit fixup can start in the
                # final 4 bytes of a page. The chain location, not the word, is bounded.
                if address >= page_end:
                    raise ValueError("Fixup chain exits its page")
                raw = struct.unpack_from("<Q", collection, file_offset_for_address(segments, address))[0]
                visited_count += 1
                if any(start <= address < end for start, end in ranges.values()):
                    records[address] = raw
                next_stride = (raw >> 51) & 0xFFF
                if not next_stride:
                    break
                address += next_stride * 4

    cache_sha256 = hashlib.sha256(collection).hexdigest()
    manifests = {}
    for vtable_symbol, (table_start, table_end) in ranges.items():
        rows, problems = [], []
        for address in range(table_start, table_end, 8):
            raw = struct.unpack_from("<Q", collection, file_offset_for_address(segments, address))[0]
            row = {"table_offset": hex(address - table_start),
                   "address_unslid": hex(address), "raw_on_disk": hex(raw),
                   "chain_covered": address in records}
            if address in records:
                target_offset, cache_level = raw & 0x3FFFFFFF, (raw >> 30) & 3
                target = base + target_offset if cache_level == 0 else None
                row.update({
                    "vptr_slot_offset": hex(address - table_start - 16),
                    "is_auth": bool(raw >> 63),
                    "key": (raw >> 49) & 3,
                    "key_name": ["IA", "IB", "DA", "DB"][(raw >> 49) & 3],
                    "address_diversity": bool((raw >> 48) & 1),
                    "diversity": hex((raw >> 32) & 0xFFFF),
                    "cache_level": cache_level,
                    "target_offset": hex(target_offset),
                    "target_unslid": hex(target) if target is not None else None,
                    "target_symbols": sorted(symbols.get(target, [])),
                    "target_segment": segment_name(target) if target is not None else None,
                })
                if not row["is_auth"] or target is None or row["target_segment"] != "__TEXT_EXEC":
                    problems.append(f"Unexpected pointer at {address:#x}")
            elif raw:
                problems.append(f"Nonzero nonfixup word at {address:#x}")
            rows.append(row)
        manifests[vtable_symbol] = {
            "schema": "offline-vtable-pac-v1",
            "cache_path": str(cache_path),
            "cache_sha256": cache_sha256,
            "collection_uuid": collection_uuid,
            "collection_preferred_base": hex(base),
            "chained_fixups_file_offset": hex(fixoff),
            "chained_fixups_size": hex(fixsize),
            "pointer_formats": sorted(formats),
            "chains_walked": chain_count, "fixups_walked": visited_count,
            "vtable_symbol": vtable_symbol,
            "vtable_address_unslid": hex(table_start),
            "vtable_segment": segment_name(table_start),
            "candidate_bound_address_unslid": hex(table_end),
            "candidate_bound_symbols": sorted(vtables[table_end]),
            "candidate_bound_method": "next distinct defined vtable symbol",
            "chain_covered_entries": sum(1 for row in rows if row["chain_covered"]),
            "structural_check_passed": not problems,
            "problems": problems, "entries": rows,
        }
    return manifests
