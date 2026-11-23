import struct


def decode_usb_record(data, frame, timestamp, truncated):
    if len(data) < 40:
        return None
    header_length = data[2]
    if not 40 <= header_length <= len(data):
        raise ValueError("Invalid Darwin USB header length at frame{}".format(frame))
    return {
        "frame": frame,
        "timestamp": timestamp,
        "route": struct.unpack_from("<I", data, 24)[0],
        "event": data[3],
        "status": struct.unpack_from("<I", data, 8)[0],
        "requestID": struct.unpack_from("<Q", data, 16)[0],
        "endpoint": data[30],
        "payload": data[header_length:],
        "truncated": truncated,
    }
