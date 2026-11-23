import struct


def decode_pcap_header(header):
    formats = {
        b"\xd4\xc3\xb2\xa1": ("<", 1000000),
        b"\xa1\xb2\xc3\xd4": (">", 1000000),
        b"\x4d\x3c\xb2\xa1": ("<", 1000000000),
        b"\xa1\xb2\x3c\x4d": (">", 1000000000),
    }
    if header[:4] not in formats:
        raise ValueError("Expected classic pcap, not pcapng")
    endian, timestamp_scale = formats[header[:4]]
    if struct.unpack_from(endian + "HH", header, 4) != (2, 4):
        raise ValueError("Expected pcap version2.4")
    if struct.unpack_from(endian + "I", header, 20)[0] != 266:
        raise ValueError("Expected Darwin USB linktype266 from XHC0")
    return endian, timestamp_scale
