import hashlib
import json
import subprocess
import sys

from .CheckControllerVptrSigning import check_controller_vptr_signing
from .CheckDeviceRequestSlot import check_device_request_slot
from .DecodeVtablePac import decode_vtable_pac
from .DecompressKernelPayload import MACH_O_64, decompress_kernel_payload
from .ExtractKernelPayload import extract_kernel_payload
from .FormatSymbolList import format_symbol_list
from .ListCollectionSymbols import list_collection_symbols
from .ReadCollectionSegments import read_collection_segments
from .ReadCollectionVersion import read_collection_version
from .ReadGeneratedPins import read_generated_pins
from .RetargetKernelPins import retarget_kernel_pins

CONTROLLER_VTABLE = "__ZTV17AppleT8142USBXHCI"
DEVICE_VTABLE = "__ZTV15IOUSBHostDevice"


def regenerate_kernel_table(project, collection_path, kernel_version, work, check):
    """Rebuild the controller table and exact-kernel checks for one kernel collection.

    Sources change only after the collection matches kernel_version and every structural
    check passes; otherwise this stops with the reason. With check true nothing in the
    project is written: it confirms the committed table and checks match the collection.
    """
    container = collection_path.read_bytes()
    if container[:4] == MACH_O_64:
        collection = container
    else:
        collection = decompress_kernel_payload(*extract_kernel_payload(container))
    segments = read_collection_segments(collection)
    symbol_rows = list_collection_symbols(collection)
    version = read_collection_version(collection, segments, symbol_rows)
    if version != kernel_version:
        raise SystemExit(f"The collection is for a different kernel:\n  {version}\n"
                         f"expected:\n  {kernel_version}")
    cache = work / "kernelcache.decoded"
    manifests = decode_vtable_pac(collection, segments, symbol_rows,
                                  [CONTROLLER_VTABLE, DEVICE_VTABLE], cache)
    check_controller_vptr_signing(collection, segments, symbol_rows)
    check_device_request_slot(manifests[DEVICE_VTABLE])

    # Keep the inputs beside each other so verify-candidate.py can reuse them after a build.
    work.mkdir(parents=True, exist_ok=True)
    cache.write_bytes(collection)
    (work / "kernel-symbols.txt").write_text(format_symbol_list(symbol_rows))
    (work / "kernel-segments.json").write_text(json.dumps(segments))
    manifest = work / "apple-t8142-vtable-pac.json"
    manifest.write_text(json.dumps(manifests[CONTROLLER_VTABLE], indent=2) + "\n")

    header = project / "DigitsDriver/PinnedControllerTable.generated.hpp"
    old_pins = read_generated_pins(header)
    new_pins = (version, hashlib.sha256(collection).hexdigest())
    if check and old_pins != new_pins:
        raise SystemExit(f"The committed table is for another kernel:\n  {old_pins[0]}\n"
                         "Run without --check to regenerate it for this one.")
    retarget_kernel_pins(project, old_pins, new_pins, write=False)
    command = [sys.executable, str(project / "DigitsDriver/generate-pinned-table.py"),
               "--manifest", str(manifest), "--cache", str(cache),
               "--symbols", str(work / "kernel-symbols.txt"),
               "--segments", str(work / "kernel-segments.json"),
               "--kernel-version", version, "--output", str(header)]
    if check:
        command.append("--check")
    generated = subprocess.run(command, capture_output=True, text=True)
    if generated.returncode != 0:
        raise SystemExit("The controller table could not be generated for this kernel. "
                         "AppleT8142USBXHCI no longer matches what Digits Driver expects, "
                         "so the driver needs porting, not just a new table.\n"
                         + generated.stderr.strip().splitlines()[-1])
    changed = retarget_kernel_pins(project, old_pins, new_pins, write=not check)
    return {"kernelVersion": version, "collectionSHA256": new_pins[1],
            "previousKernelVersion": old_pins[0], "changedChecks": changed,
            "workDirectory": str(work)}
