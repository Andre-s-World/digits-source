import ctypes

COMPRESSION_LZFSE = 0x801
MACH_O_64 = b"\xcf\xfa\xed\xfe"


def decompress_kernel_payload(payload, uncompressed_size):
    """Return the raw Mach-O kernel collection from an IM4P payload.

    Apple silicon kernel payloads are LZFSE ("bvx2"). macOS's own compression library
    decodes them, so no third-party tool is involved.
    """
    if payload[:4] == MACH_O_64:
        return payload
    if payload[:4] != b"bvx2":
        raise ValueError("Unsupported kernel payload encoding " + payload[:4].hex())
    library = ctypes.CDLL("/usr/lib/libcompression.dylib")
    decode = library.compression_decode_buffer
    decode.restype = ctypes.c_size_t
    decode.argtypes = [ctypes.c_void_p, ctypes.c_size_t, ctypes.c_char_p, ctypes.c_size_t,
                       ctypes.c_void_p, ctypes.c_int]
    capacity = uncompressed_size or len(payload) * 8
    while True:
        output = ctypes.create_string_buffer(capacity)
        produced = decode(output, capacity, payload, len(payload), None, COMPRESSION_LZFSE)
        if produced == 0:
            raise ValueError("LZFSE decoding failed")
        # Without a recorded size, a completely full buffer may be truncated output.
        if uncompressed_size or produced < capacity:
            break
        capacity *= 2
    if uncompressed_size and produced != uncompressed_size:
        raise ValueError("Decoded kernel size differs from the IM4P compression record")
    collection = output.raw[:produced]
    if collection[:4] != MACH_O_64:
        raise ValueError("Decoded kernel payload is not a 64-bit Mach-O")
    return collection
