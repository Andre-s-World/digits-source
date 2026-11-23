#!/usr/bin/env python3
"""Bundle the signed Digits app and frozen Driver package for offline setup.

Touch is already embedded in Digits.app. Running the historical Touch package
would replace that new app with its old host, so activation uses the new host.
This preparation command never installs, activates or loads anything.
"""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import shutil
import subprocess


def main():
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--release-directory', type=Path, default=root / 'Releases/MacOS-27.3/Components')
    parser.add_argument('--app', type=Path, default=root / '.build/DigitsAppFinal/Build/Products/Debug/Digits.app')
    options = parser.parse_args()
    app = options.app
    frozen = root / 'DigitsDriver/Packaging/TouchDevelopment/Digits.app/Contents/Library/SystemExtensions/local.digits.touch.dext'
    package = options.release_directory / 'Digits Driver 0.2.4.pkg'
    expected_package = '5c6a66c64c16ce2ecefcff7b17e8e44bd08c3fb54ab2528cbcc8a143effaaafb'
    if hashlib.sha256(package.read_bytes()).hexdigest() != expected_package:
        raise SystemExit('Frozen Driver package changed.')
    info = plistlib.loads((app / 'Contents/Info.plist').read_bytes())
    if info['CFBundleIdentifier'] != 'local.digits.touch.host' or info['CFBundleVersion'] != '0.2.7':
        raise SystemExit('Build Digits 0.2.7 before preparing installer payloads.')
    subprocess.run(['/usr/bin/codesign', '--verify', '--deep', '--strict', str(app)], check=True)
    embedded = app / 'Contents/Library/SystemExtensions/local.digits.touch.dext'
    original_files = {str(p.relative_to(frozen)): hashlib.sha256(p.read_bytes()).hexdigest()
                      for p in frozen.rglob('*') if p.is_file()}
    embedded_files = {str(p.relative_to(embedded)): hashlib.sha256(p.read_bytes()).hexdigest()
                      for p in embedded.rglob('*') if p.is_file()}
    if original_files != embedded_files:
        raise SystemExit('Embedded Touch differs from the frozen 0.1.6 driver.')
    output = root / '.build/InstallerPayloads'
    if output.exists():
        shutil.rmtree(output)
    output.mkdir()
    subprocess.run(['/usr/bin/ditto', str(app), str(output / 'Digits.app')], check=True)
    shutil.copy2(package, output / package.name)
    files = {}
    for path in sorted(output.rglob('*')):
        if path.is_symlink():
            raise SystemExit('Unexpected payload symlink: ' + str(path))
        if path.is_file():
            files[str(path.relative_to(output))] = hashlib.sha256(path.read_bytes()).hexdigest()
    manifest = {'schema': 'digits-installer-payloads-v1', 'appVersion': info['CFBundleVersion'],
                'driverVersion': '0.2.4', 'touchVersion': '0.1.6', 'files': files}
    (output / 'PayloadManifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(f'Prepared {len(files)} verified payload files. No installation performed.')


if __name__ == '__main__':
    main()
