import struct

LC_SYMTAB = 0x2
LC_SEGMENT_64 = 0x19
N_STAB = 0xE0
N_TYPE = 0x0E
N_SECT = 0x0E


def list_entry_symbols(collection, header_offset, entry):
    """Return (entry, address, kind, name) for each defined symbol of one fileset entry.

    Fileset entries share the collection's __LINKEDIT, so their symbol and string
    table offsets are offsets into the whole collection. kind is "T" for a __text
    section and "S" for any other section, as in an nm listing.
    """
    command_count = struct.unpack_from("<I", collection, header_offset + 16)[0]
    sections, symtab, offset = [], None, header_offset + 32
    for _ in range(command_count):
        command, size = struct.unpack_from("<II", collection, offset)
        if command == LC_SEGMENT_64:
            section_count = struct.unpack_from("<I", collection, offset + 64)[0]
            for index in range(section_count):
                record = offset + 72 + index * 80
                sections.append(collection[record:record + 16].split(b"\0")[0].decode())
        elif command == LC_SYMTAB:
            symtab = struct.unpack_from("<IIII", collection, offset + 8)
        offset += size
    if symtab is None:
        return []
    symbol_offset, symbol_count, string_offset, string_size = symtab
    rows = []
    for index in range(symbol_count):
        name_index, kind, section, _description, value = struct.unpack_from(
            "<IBBHQ", collection, symbol_offset + index * 16)
        if kind & N_STAB or kind & N_TYPE != N_SECT or name_index >= string_size:
            continue
        start = string_offset + name_index
        name = collection[start:collection.index(b"\0", start)].decode("utf-8", "replace")
        letter = "T" if 0 < section <= len(sections) and sections[section - 1] == "__text" else "S"
        rows.append((entry, value, letter, name))
    return rows
