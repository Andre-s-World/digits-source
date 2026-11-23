import struct

LC_SEGMENT_64 = 0x19
MH_FILESET = 0xC


def read_collection_segments(collection):
    """Return [name, vmaddr, vmsize, fileoff, filesize] for each top-level segment."""
    magic, _cpu, _subtype, filetype, command_count = struct.unpack_from("<IiiII", collection)
    if magic != 0xFEEDFACF or filetype != MH_FILESET:
        raise ValueError("Expected a 64-bit Mach-O kernel collection (MH_FILESET)")
    segments, offset = [], 32
    for _ in range(command_count):
        command, size = struct.unpack_from("<II", collection, offset)
        if size < 8 or offset + size > len(collection):
            raise ValueError("Invalid Mach-O load command")
        if command == LC_SEGMENT_64:
            name = collection[offset + 8:offset + 24].split(b"\0")[0].decode()
            vmaddr, vmsize, fileoff, filesize = struct.unpack_from("<QQQQ", collection, offset + 24)
            segments.append([name, vmaddr, vmsize, fileoff, filesize])
        offset += size
    return segments
