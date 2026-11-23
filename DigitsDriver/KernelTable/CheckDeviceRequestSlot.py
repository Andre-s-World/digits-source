DEVICE_REQUEST = ("__ZN15IOUSBHostDevice13deviceRequestEP9IOServiceRN11StandardUSB"
                  "13DeviceRequestEPvRjj")


def check_device_request_slot(device_manifest):
    """Require the kernel's IOUSBHostDevice vtable to match the driver's compiled override.

    XeneonStringDevice overrides the synchronous raw-buffer deviceRequest. The compiler
    places that override at vtable slot 0xb68 with IA key, address diversity and
    discriminator 0x4aeb. If the kernel's slot differs, the override would be called
    in place of a different method.
    """
    if not device_manifest["structural_check_passed"]:
        raise SystemExit("IOUSBHostDevice vtable failed its structural check.")
    rows = [row for row in device_manifest["entries"] if row.get("vptr_slot_offset") == "0xb68"]
    if len(rows) != 1:
        raise SystemExit("IOUSBHostDevice has no slot 0xb68; the driver needs porting.")
    row = rows[0]
    if (DEVICE_REQUEST not in row["target_symbols"] or row["diversity"] != "0x4aeb" or
            not row["is_auth"] or row["key"] != 0 or not row["address_diversity"]):
        raise SystemExit("IOUSBHostDevice slot 0xb68 is no longer deviceRequest/0x4aeb; "
                         "the driver needs porting, not just a new table.")
