import json
import re


def read_generated_pins(header_path):
    """Return (kernel version, collection SHA-256) from PinnedControllerTable.generated.hpp."""
    text = header_path.read_text()
    version = re.search(r"^constexpr char kKernelVersion\[\] = (\".*\");$", text, re.MULTILINE)
    digest = re.search(r'^constexpr char kImageSHA256\[\] = "([0-9a-f]{64})";$', text, re.MULTILINE)
    if not version or not digest:
        raise SystemExit(f"{header_path.name} has no kernel version or collection hash.")
    return json.loads(version.group(1)), digest.group(1)
