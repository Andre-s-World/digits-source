#!/usr/bin/env python3
"""Archive/parse a pcap stream only; this program never opens USB or HID."""
import argparse
from pathlib import Path
import signal
import sys

from ReportReader.RunReportCapture import run_report_capture


if __name__ == "__main__":
    arguments = argparse.ArgumentParser(description=__doc__)
    arguments.add_argument("--output", type=Path, required=True)
    arguments.add_argument("--input", type=Path, help="Offline saved pcap; otherwise read stdin")
    options = arguments.parse_args()
    # Ctrl-C belongs to the shell; draining tcpdump's EOF preserves its final records.
    signal.signal(signal.SIGINT, signal.SIG_IGN)
    if options.input:
        with options.input.open("rb") as source:
            status = run_report_capture(source, options.output, False)
    else:
        status = run_report_capture(sys.stdin.buffer, options.output, True)
    sys.exit(status)
