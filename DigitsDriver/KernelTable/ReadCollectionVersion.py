from .FileOffsetForAddress import file_offset_for_address


def read_collection_version(collection, segments, symbol_rows):
    """Return the kernel version string stored at the collection's _version symbol."""
    addresses = {address for _entry, address, _kind, name in symbol_rows if name == "_version"}
    if len(addresses) != 1:
        raise ValueError("Expected exactly one _version symbol")
    offset = file_offset_for_address(segments, addresses.pop())
    version = collection[offset:offset + 512].split(b"\0", 1)[0]
    if not version.startswith(b"Darwin Kernel Version ") or len(version) >= 511:
        raise ValueError("Unexpected kernel version string")
    return version.decode("ascii")
