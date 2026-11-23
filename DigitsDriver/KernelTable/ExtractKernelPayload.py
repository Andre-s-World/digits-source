from .ReadDerElement import read_der_element

SEQUENCE = 0x30
IA5_STRING = 0x16
OCTET_STRING = 0x04


def extract_kernel_payload(container):
    """Return (payload, uncompressed size or None) from an IMG4 or IM4P kernel container.

    IMG4 wraps an IM4P together with its signed manifest, which is not needed here.
    The IM4P holds the type "krnl", a description, the payload and, after it, an
    optional (algorithm, uncompressed size) compression record.
    """
    tag, start, end = read_der_element(container, 0)
    if tag != SEQUENCE:
        raise ValueError("Kernel container is not a DER sequence")
    tag, name_start, name_end = read_der_element(container, start)
    if tag == IA5_STRING and container[name_start:name_end] == b"IMG4":
        tag, start, end = read_der_element(container, name_end)
        if tag != SEQUENCE:
            raise ValueError("IMG4 does not contain an IM4P sequence")
        tag, name_start, name_end = read_der_element(container, start)
    if tag != IA5_STRING or container[name_start:name_end] != b"IM4P":
        raise ValueError("Expected an IM4P kernel payload")
    fields, position = [], name_end
    while position < end:
        field = read_der_element(container, position)
        fields.append(field)
        position = field[2]
    if len(fields) < 3 or fields[0][0] != IA5_STRING or fields[2][0] != OCTET_STRING:
        raise ValueError("Unexpected IM4P layout")
    if container[fields[0][1]:fields[0][2]] != b"krnl":
        raise ValueError("IM4P payload is not a kernel")
    payload = container[fields[2][1]:fields[2][2]]
    uncompressed_size = None
    for tag, start, end in fields[3:]:
        if tag != SEQUENCE:
            continue
        values, position = [], start
        while position < end:
            _, value_start, value_end = read_der_element(container, position)
            values.append(int.from_bytes(container[value_start:value_end], "big"))
            position = value_end
        if len(values) == 2:
            uncompressed_size = values[1]
    return payload, uncompressed_size
