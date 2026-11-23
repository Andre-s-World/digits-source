import json


def write_capture_summary(output, summary, report_log):
    (output / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    line = "FINAL: frames={} physical0D={} mouse07={} maxContacts={} warning0D={} errors={}".format(
        summary["completeFrames"], summary["physical0DReports"], summary["mouse07Reports"],
        summary["maximumActiveContacts"], summary["0DReportsWithWarnings"], summary["targetErrorEvents"]
    )
    if summary["error"]:
        line += " parserError=" + summary["error"]
    report_log.write(line + "\n")
    report_log.flush()
    print(line, flush=True)
