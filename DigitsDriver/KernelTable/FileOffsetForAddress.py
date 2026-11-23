def file_offset_for_address(segments, address):
    """Map an unslid collection address to its offset in the collection file."""
    for _name, vmaddr, _vmsize, fileoff, filesize in segments:
        # Only file-backed bytes exist on disk; zero-fill tails have no offset.
        if vmaddr <= address < vmaddr + filesize:
            return fileoff + address - vmaddr
    raise ValueError(f"Unmapped collection address {address:#x}")
