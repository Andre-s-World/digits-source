import struct
import sys

from .DecodePcapHeader import decode_pcap_header
from .DecodeUsbRecord import decode_usb_record
from .ReadCaptureBytes import read_capture_bytes
from .RecordTargetPacket import record_target_packet
from .WriteCaptureSummary import write_capture_summary


def run_report_capture(source, output, live):
    output.mkdir(parents=True, exist_ok=True)
    summary = {
        "schema": "digits-stage1-capture-v1",
        "capture": str((output / "capture.pcap").resolve()),
        "live": live,
        "targetRoute": "00140000",
        "globalHeaderReceived": False,
        "completeFrames": 0,
        "targetFrames": 0,
        "targetControlRequests": 0,
        "targetErrorEvents": 0,
        "truncatedFrames": 0,
        "physical0DReports": 0,
        "mouse07Reports": 0,
        "maximumActiveContacts": 0,
        "0DReportsWithWarnings": 0,
        "successfulInputReports": {},
        "error": None,
    }
    status = 0
    with (output / "capture.pcap").open("xb") as archive, (output / "reports.txt").open("x") as report_log:
        try:
            header = read_capture_bytes(source, archive, 24)
            endian, timestamp_scale = decode_pcap_header(header)
            summary["globalHeaderReceived"] = True
            if live:
                (output / "READY").write_text("Validated tcpdump pcap global header, linktype266.\n")
                print("READY: tcpdump header received; recording ALL XHC0 frames. Target route00140000 EP81/0D and EP83/07. Ctrl-C stops.", flush=True)
            while True:
                record = read_capture_bytes(source, archive, 16, allow_eof=True)
                if record is None:
                    break
                seconds, fraction, included, original = struct.unpack(endian + "IIII", record)
                if included > 16 * 1024 * 1024:
                    raise ValueError("Unreasonable pcap record length")
                data = read_capture_bytes(source, archive, included)
                summary["completeFrames"] += 1
                truncated = included < original
                summary["truncatedFrames"] += int(truncated)
                packet = decode_usb_record(
                    data, summary["completeFrames"], seconds + fraction / timestamp_scale, truncated
                )
                line = record_target_packet(packet, summary)
                if line:
                    report_log.write(line + "\n")
                    report_log.flush()
                    print(line, flush=True)
        except (OSError, ValueError, struct.error) as error:
            summary["error"] = str(error)
            status = 1
            print("Capture parser: " + str(error), file=sys.stderr, flush=True)
        finally:
            write_capture_summary(output, summary, report_log)
    return status
