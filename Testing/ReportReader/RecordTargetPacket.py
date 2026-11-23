from .DecodeDigitizerReport import decode_digitizer_report
from .FormatReportLine import format_report_line


def record_target_packet(packet, summary):
    if packet is None or packet["route"] != 0x00140000:
        return None
    summary["targetFrames"] += 1
    if packet["status"]:
        summary["targetErrorEvents"] += 1
    payload = packet["payload"]
    endpoint = packet["endpoint"]
    if packet["event"] == 0 and endpoint & 15 == 0 and len(payload) >= 8:
        summary["targetControlRequests"] += 1
        return "REQUEST frame={} request={} EP00 setup={} raw={}".format(
            packet["frame"], packet["requestID"], payload[:8].hex(), payload.hex()
        )
    if packet["event"] != 1 or packet["status"] or packet["truncated"] or not payload:
        return None
    if endpoint not in (0x81, 0x83):
        return None
    report_key = "EP{:02X}/{:02X}/{}B".format(endpoint, payload[0], len(payload))
    summary["successfulInputReports"][report_key] = (
        summary["successfulInputReports"].get(report_key, 0) + 1
    )
    details = None
    if endpoint == 0x81 and len(payload) == 54 and payload[0] == 0x0D:
        summary["physical0DReports"] += 1
        details = decode_digitizer_report(payload)
        summary["maximumActiveContacts"] = max(summary["maximumActiveContacts"], details["active"])
        if details["warnings"]:
            summary["0DReportsWithWarnings"] += 1
    elif endpoint == 0x83 and payload[0] == 0x07:
        summary["mouse07Reports"] += 1
    return format_report_line(packet, details)
