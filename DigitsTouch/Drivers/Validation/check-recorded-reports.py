#!/usr/bin/env python3
"""Offline check against recorded Stage1 physical reports; never opens a USB/HID service."""
import json
from pathlib import Path
import subprocess
import tempfile

source_root = Path(__file__).resolve().parents[1]
workspace_root = source_root.parents[1]
evidence_path = workspace_root / 'BuildReports/passed-stage1-20261111/decoded-excerpt-reports.jsonl'
records = [json.loads(line) for line in evidence_path.read_text().splitlines() if line.strip()]
reports = [bytes.fromhex(record['raw_hex']) for record in records]
assert reports and all(len(report) == 54 for report in reports)
rows = ',\n'.join('    {' + ','.join(str(value) for value in report) + '}' for report in reports)
check_source = r'''
#include "DigitsTouchReport.hpp"
#include <stdint.h>
#include <stdio.h>
#include <string.h>
static const uint8_t recorded[][54] = {
RECORDS
};
int main() {
    uint8_t output[54];
    for (const auto &report : recorded) {
        if (!DigitsTouch::NormalizePhysicalReport(report, sizeof(report), output)) return 1;
        for (size_t slot = 0; slot < 10; ++slot) {
            const size_t offset = 1 + slot * 5;
            if (((output[offset] >> 1) & 1) != (report[offset] & 1)) return 2;
            if ((output[offset] >> 4) != (report[offset] >> 4)) return 3;
        }
    }
    uint8_t input[54]{};
    input[0] = 0x0d; input[1] = 0x11; input[53] = 1;
    input[2] = 0; input[3] = 0x40; input[4] = 0x80; input[5] = 0x25;
    if (!DigitsTouch::NormalizePhysicalReport(input, 54, output)) return 4;
    if (output[2] != 0xff || output[3] != 0x3f || output[4] != 0x7f || output[5] != 0x25)
        return 5;
    input[2] = 1;
    if (DigitsTouch::NormalizePhysicalReport(input, 54, output)) return 6;
    input[2] = 0; input[3] = 0;
    input[6] = 0x11; input[53] = 2;
    if (DigitsTouch::NormalizePhysicalReport(input, 54, output)) return 7;
    input[6] = 0; input[53] = 11;
    if (DigitsTouch::NormalizePhysicalReport(input, 54, output)) return 8;
    input[53] = 1; input[0] = 0x07;
    if (DigitsTouch::NormalizePhysicalReport(input, 54, output)) return 9;
    input[0] = 0x0d;
    if (DigitsTouch::NormalizePhysicalReport(input, 53, output)) return 10;
    printf("Accepted %zu recorded physical reports; bounded edge repair and malformed frames checked.\n",
        sizeof(recorded) / sizeof(recorded[0]));
    return 0;
}
'''.replace('RECORDS', rows)
with tempfile.TemporaryDirectory(prefix='digits-recorded-reports-') as temporary:
    source = Path(temporary) / 'check.cpp'
    binary = Path(temporary) / 'check'
    source.write_text(check_source)
    subprocess.run(['/usr/bin/clang++', '-std=c++17', '-Wall', '-Wextra', '-Werror',
                    '-I', str(source_root / 'Touch'), str(source),
                    str(source_root / 'Touch/Source/DigitsTouch_NormalizePhysicalReport.cpp'),
                    '-o', str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
