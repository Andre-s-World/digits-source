import struct

from .ListEntrySymbols import list_entry_symbols

LC_FILESET_ENTRY = 0x80000035


def list_collection_symbols(collection):
    """Return (entry, address, kind, name) for the defined symbols of every fileset entry."""
    command_count = struct.unpack_from("<I", collection, 16)[0]
    rows, offset = [], 32
    for _ in range(command_count):
        command, size = struct.unpack_from("<II", collection, offset)
        if command == LC_FILESET_ENTRY:
            _vmaddr, header_offset, name_offset = struct.unpack_from("<QQI", collection, offset + 8)
            entry = collection[offset + name_offset:offset + size].split(b"\0")[0].decode()
            rows.extend(list_entry_symbols(collection, header_offset, entry))
        offset += size
    if not rows:
        raise ValueError("The kernel collection has no fileset entry symbols")
    return rows
