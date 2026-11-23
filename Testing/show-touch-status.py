#!/usr/bin/env python3
"""Read one bounded Digits registry snapshot without opening a driver userclient."""
import datetime
import plistlib
import subprocess


def main():
    print('Digits Touch status — ' + datetime.datetime.now().astimezone().isoformat(timespec='seconds'),
          flush=True)
    registration = subprocess.run(['/usr/bin/systemextensionsctl', 'list'],
                                  check=True, capture_output=True, text=True)
    entries = [line.strip() for line in registration.stdout.splitlines()
               if 'local.digits.touch ' in line]
    print('Extension: ' + (' | '.join(entries) if entries else 'not registered'))
    # The kernel class is IOUserService; DigitsUSBTransport is its registry name/user class.
    registry = subprocess.run(['/usr/sbin/ioreg', '-p', 'IOService', '-a', '-l', '-r', '-n', 'DigitsUSBTransport',
                               '-d', '5'], check=True, capture_output=True)
    # ioreg emits no plist at all when a named service is absent.
    roots = plistlib.loads(registry.stdout) if registry.stdout.strip() else []
    providers = [entry for entry in roots
                 if entry.get('IOUserClass') == 'DigitsUSBTransport' and
                 'local.digits.touch' in (entry.get('IOUserServerName'),
                                           entry.get('CFBundleIdentifier'))]
    if not providers:
        print('USB provider: not attached. No live Touch publication can be verified.')
        return
    for provider in providers:
        print('USB provider: registry ID ' + str(provider.get('IORegistryEntryID', 'unavailable')))
        for key in ('DriverVersion', 'PhysicalUSBRegistryID', 'USBInterfaceRegistryID',
                    'BindingState', 'HIDPublicationState', 'HIDPublicationResult',
                    'HIDCreationAttempts'):
            value = provider.get(key, 'not published')
            if key == 'HIDPublicationResult' and isinstance(value, int):
                value = '0x%08x' % value
            print('  ' + key + ': ' + str(value))
        pending = list(provider.get('IORegistryEntryChildren', []))
        children = []
        while pending:
            entry = pending.pop()
            pending.extend(entry.get('IORegistryEntryChildren', []))
            # IOUserHIDDevice publishes its name and AppleUserHIDDevice kernel class,
            # without retaining the DriverKit IOUserClass property on the HID child.
            if entry.get('IORegistryEntryName') == 'DigitsTouchDevice' and \
                    entry.get('IOObjectClass') == 'AppleUserHIDDevice':
                children.append(entry)
        print('  Native HID children: ' + str(len(children)))
        for child in children[:4]:
            print('    ID ' + str(child.get('IORegistryEntryID', 'unavailable')) +
                  '; displayUUID=' + str(child.get('displayUUID', 'not published')) +
                  '; serviceState=' + str(child.get('IOServiceState', 'not published')))
            descendants = child.get('IORegistryEntryChildren', [])
            print('    Published child services: ' +
                  (', '.join(str(entry.get('IOObjectClass', entry.get('IORegistryEntryName', '?')))
                             for entry in descendants) or 'none'))
        if len(children) > 4:
            print('    Additional child detail omitted; total above is exact for this snapshot.')
    print('Native app contact/gesture behavior still needs an app test; registry state alone is not proof.')


if __name__ == '__main__':
    main()
