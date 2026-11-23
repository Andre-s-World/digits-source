def read_capture_bytes(source, archive, size, allow_eof=False):
    """Preserve every byte, including an incomplete final record, before decoding it."""
    collected = bytearray()
    while len(collected) < size:
        chunk = source.read(size - len(collected))
        if not chunk:
            if allow_eof and not collected:
                return None
            raise ValueError("Capture ended inside a pcap header or record")
        archive.write(chunk)
        archive.flush()
        collected.extend(chunk)
    return bytes(collected)
