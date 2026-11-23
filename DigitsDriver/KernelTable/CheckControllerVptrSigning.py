import bisect
import struct

from .FileOffsetForAddress import file_offset_for_address

CONSTRUCTORS = (
    "__ZN17AppleT8142USBXHCIC1EPK11OSMetaClass",
    "__ZN17AppleT8142USBXHCIC2EPK11OSMetaClass",
    "__ZN17AppleT8142USBXHCIC1Ev",
    "__ZN17AppleT8142USBXHCIC2Ev",
)
VPTR_DISCRIMINATOR = 0xCDA1


def check_controller_vptr_signing(collection, segments, symbol_rows):
    """Require every AppleT8142USBXHCI constructor to sign its vptr the way the driver does.

    PinnedController_signVptr.cpp signs the shadow table with the DA key, blended with
    the object address and 0xcda1. Each constructor must contain that blend
    (movk xN, #0xcda1, lsl #48) followed closely by pacda using xN as the modifier.
    """
    addresses = sorted({address for _entry, address, _kind, _name in symbol_rows})
    by_name = {}
    for _entry, address, _kind, name in symbol_rows:
        by_name.setdefault(name, set()).add(address)
    for constructor in CONSTRUCTORS:
        starts = by_name.get(constructor, set())
        if len(starts) != 1:
            raise SystemExit(f"Kernel has no unique {constructor}; the controller changed.")
        start = starts.pop()
        end = addresses[bisect.bisect_right(addresses, start)]
        words = struct.unpack_from(f"<{(end - start) // 4}I", collection,
                                   file_offset_for_address(segments, start))
        signed = False
        for index, word in enumerate(words):
            # MOVK (64-bit, hw=3): 0xF2E00000 | imm16 << 5 | Rd.
            if (word & 0xFFE00000) != 0xF2E00000 or (word >> 5) & 0xFFFF != VPTR_DISCRIMINATOR:
                continue
            register = word & 31
            # PACDA Xd, Xn: 0xDAC10800 | Rn << 5 | Rd, with Xn the blended modifier.
            signed = signed or any((following & 0xFFFFF800) == 0xDAC10800 and
                                   (following >> 5) & 31 == register
                                   for following in words[index + 1:index + 6])
        if not signed:
            raise SystemExit(f"{constructor} no longer signs its vptr with DA/0xcda1; "
                             "the driver needs porting, not just a new table.")
