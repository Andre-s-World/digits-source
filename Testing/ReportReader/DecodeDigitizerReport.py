import struct


def decode_digitizer_report(report):
    contacts = []
    for slot in range(10):
        position = 1 + 5 * slot
        if report[position] & 1:
            x, y = struct.unpack_from("<HH", report, position + 1)
            contacts.append({"id": report[position] >> 4, "x": x, "y": y})
    warnings = []
    if len({contact["id"] for contact in contacts}) != len(contacts):
        warnings.append("duplicate-ID")
    if any(contact["x"] > 16383 or contact["y"] > 9599 for contact in contacts):
        warnings.append("out-of-bounds")
    if report[53] > 10:
        warnings.append("count-over-ten")
    return {
        "contacts": contacts,
        "active": len(contacts),
        "count": report[53],
        "scan": struct.unpack_from("<H", report, 51)[0],
        "warnings": warnings,
    }
