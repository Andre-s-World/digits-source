def read_der_element(data, offset):
    """Return (tag, content start, content end) for the DER element at offset."""
    if offset + 2 > len(data):
        raise ValueError("Truncated DER header")
    tag = data[offset]
    length = data[offset + 1]
    start = offset + 2
    if length & 0x80:
        # Long form: the low bits count the big-endian length bytes that follow.
        count = length & 0x7F
        if count == 0 or count > 8:
            raise ValueError("Unsupported DER length")
        length = int.from_bytes(data[start:start + count], "big")
        start += count
    end = start + length
    if end > len(data):
        raise ValueError("Truncated DER element")
    return tag, start, end
