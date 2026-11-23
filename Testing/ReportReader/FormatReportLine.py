import datetime


def format_report_line(packet, details):
    stamp = datetime.datetime.fromtimestamp(
        packet["timestamp"], datetime.timezone.utc
    ).isoformat(timespec="microseconds")
    line = "{} frame={} request={} route=00140000 EP{:02X} report={:02X}".format(
        stamp, packet["frame"], packet["requestID"], packet["endpoint"], packet["payload"][0]
    )
    if details:
        points = " ".join(
            "ID{id}({x},{y})".format(**contact)
            for contact in details["contacts"]
        ) or "all lifted"
        line += " active={} count={} scan={} {}".format(
            details["active"], details["count"], details["scan"], points
        )
        if details["warnings"]:
            line += " [{}]".format(",".join(details["warnings"]))
    return line + " raw=" + packet["payload"].hex()
