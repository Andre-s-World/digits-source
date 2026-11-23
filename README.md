# Digits

Native multitouch for the Corsair Xeneon Edge on macOS.

> **Experimental software. Install at your own risk.**
>
> Digits needs System Integrity Protection disabled, Permissive Security and an unsigned kernel extension. While building it I ran into crashes, complete freezes and more than one macOS reinstall. It works on my Mac; it may not work on yours. Make a full backup first and only install it on a Mac you know how to recover. It is provided as is, without any warranty.

## What it does

Out of the box, macOS treats the Edge's touch panel as a basic pointer: one touch at a time, driving your regular mouse cursor.

Digits turns it into a native macOS touchscreen:

- Up to ten fingers at once.
- Touches land on the Edge itself. Your mouse pointer stays where it was on your other screen.
- Multi-finger gestures like pinch, rotate and pan arrive in apps as native input.
- Nothing has to stay open. Once installed, touch works with the Digits app closed. There is no background helper, login item or input-forwarding service.

### How it works

There are two drivers and an app.

1. **Digits Driver** is a kernel extension that loads early at startup. When the Edge's touch panel connects over USB, macOS reads its string descriptors starting with a short two-byte request. For this one device, Digits Driver sends those string requests as full 255-byte transfers instead, and with that exchange the panel starts sending its `0x0D` multitouch reports. The driver also attaches your saved display choice to the panel's USB device, so Digits Touch can find it at boot.
2. **Digits Touch** is a DriverKit extension. It claims only the panel's touch interface, reads the `0x0D` reports straight from USB, adds the confidence data macOS expects and publishes a native HID touchscreen tied to the Edge's display.
3. **Digits** is the app. Use it to choose the touch display, check that both drivers are running, open the full-screen Tester, or uninstall everything.

Touch reports go from USB to DriverKit to macOS. They never pass through the app, a socket or a helper process. Your display choice is saved on your Mac in `/Library/Application Support/Digits/DigitsDisplayBinding.plist`. No display ID is built into the source or the installer.

## Requirements

Digits is locked to the exact setup I tested. Matching only some of this list is not enough.

- **Display:** a Corsair Xeneon Edge whose touch controller identifies as USB `27C0:0859`, revision `0150`.
- **Mac:** Apple silicon with the `AppleT8142USBXHCI` USB controller, with the Edge plugged into the port I tested (USB route `0x00140000`).
- **macOS:** 27.3 running Darwin 27.3.0 built October 30, 2026 (`xnu-13432.60.57~99/RELEASE_ARM64_T6050`). Check yours with `uname -v`. The driver is pinned to that kernel collection (SHA-256 `d1003b5143ffd88439b4d45b6017f587171cfe6855660bed05370a2ea5db9fe9`), the installer refuses any other kernel, and a macOS update needs a new driver build.
- **Security settings:** SIP disabled, **Permissive Security**, and third-party kernel extensions allowed. Reduced Security is not enough.
- **Signing:** the app and Digits Touch carry Apple Development signatures and only run on Macs registered in my provisioning profiles. A new Mac has to be added and the release re-signed and repackaged before it will install.
- **A backup** you know how to restore.

To build from source you also need Xcode 27 with the macOS 27 SDK, [XcodeGen](https://github.com/yonaskolb/XcodeGen), Python 3, and an Apple Developer team with DriverKit development provisioning.

## Install

The full guide, with screenshots of every approval screen, is in the binaries repository: [MacOS-27.3/INSTALL.md](https://github.com/Andre-s-World/digits-binaries/blob/main/MacOS-27.3/INSTALL.md). Here is the short version.

### 1. Get the release

The release is a password-protected ZIP in [Andre-s-World/digits-binaries](https://github.com/Andre-s-World/digits-binaries). Contact me before installing. I'll confirm your Mac and macOS build are supported, add your Mac to the provisioning profiles, and send you a repackaged build and the password. Send your Mac's Provisioning UDID (**System Information → Hardware**) privately, never in a public issue.

Extract the ZIP. **Digits Installer 0.1.4.dmg** contains everything; nothing is downloaded during installation.

### 2. Prepare macOS security (once)

Skip this step if your Mac is already set up.

1. Shut down. Hold the power button until the startup options appear, then choose **Options → Continue** to enter Recovery.
2. Open **Utilities → Terminal** and run:

   ```sh
   csrutil disable
   bputil -n -k
   ```

3. Restart into macOS.

`bputil -n -k` selects Permissive Security and allows kernel extensions. The Digits installer never changes these settings for you.

### 3. Run the installer

Keep the Edge connected to the same port the whole time.

1. Open the DMG, copy **Digits Installer.app** to a writable folder such as your Desktop, and open that copy. If macOS blocks it, use **Open Anyway** in **System Settings → Privacy & Security**.
2. Choose the Edge's display from the list and click **Install**. Approve the administrator prompt.
3. **Allow Digits Touch.** Approve the driver extension request. If you dismissed it, go to **System Settings → General → Login Items & Extensions → Driver Extensions** and turn on **Digits Touch**.
4. **Allow Digits Driver.** Choose **Open System Settings**, or go to **System Settings → Privacy & Security** and click **Allow** next to Digits Driver. When macOS offers to restart, choose **Restart Later**.
5. **Finish the second password prompt.** macOS separately asks for your password to update its kernel cache. Do not restart until that is done. Then click **Check Approval** in the installer.
6. Click **Reboot**, or restart yourself, with the Edge still connected.

After logging in, open **Digits** from Applications. The footer should show Digits Touch active and Digits Driver armed. You can close the app and touch keeps working.

### Try it

Click **Tester** in Digits. It opens full-screen on the Edge and shows:

- each finger in its own color
- a tile you can drag, pinch, rotate and tap
- counters for taps (one to ten fingers) and swipes (one to five)
- a live stream of the touch reports

Press **Esc** to leave full screen and **Close** to exit.

### Change the display or uninstall

- **Rebind:** choose **Digits → Rebind Display**, pick the display, click **Use This Display**, then restart.
- **Uninstall:** choose **Digits → Uninstall Digits**, or **Uninstall** on the installer's first screen. Approve the prompts, keep the app open until it finishes, then restart.

Uninstalling removes the app, both drivers, the display choice, settings, logs and package receipts. It does not turn SIP or your startup security back on; do that separately from Recovery.

## What's included

This folder is the complete source for the current release.

| Component | Version | What it is |
| --- | --- | --- |
| Digits | 0.2.7 | The app: display choice, driver status, Tester and uninstall |
| Digits Installer | 0.1.4 | Step-by-step installer that bundles everything offline |
| Digits Driver | 0.2.4 | Early-boot USB kernel extension and its `digits-driver-ctl` status tool |
| Digits Touch | 0.1.6 | DriverKit extension that turns the panel's reports into native touch |

| Folder | Contents |
| --- | --- |
| [DigitsApp](DigitsApp/) | The Digits app (AppKit) and its one-shot maintenance tool for display changes and removal |
| [DigitsTests](DigitsTests/) | The Tester screen built into Digits |
| [DigitsDriver](DigitsDriver/) | Digits Driver: kernel extension source, control tool, standalone build scripts and package scripts |
| [DigitsTouch](DigitsTouch/) | Digits Touch: USB transport, HID touchscreen and user client, plus a small standalone host app that activates it |
| [DigitsInstaller](DigitsInstaller/) | Digits Installer: interface, backend and its maintenance tool |
| [Testing](Testing/) | Passive touch-report capture and status tools |
| [Tools](Tools/) | Build, package and install scripts |
| [Xcode](Xcode/), [project.json](project.json), [Digits.xcodeproj](Digits.xcodeproj/) | The Xcode project and the XcodeGen spec it is generated from |

### Building

Open `Digits.xcodeproj` in Xcode 27. The shared schemes are:

- **Digits**
- **Digits Installer**
- **Digits Driver**
- **Digits Driver Control**
- **Digits Touch**
- **Digits Touch DEXT**
- **Digits Maintenance**
- **Digits Installer Maintenance**

Or use the scripts in [Tools](Tools/):

- `Tools/build-driver.sh` and `Tools/build-touch.sh` regenerate the project with XcodeGen and build unsigned debug copies of the drivers.
- `Tools/build-touch-development.sh <TEAM_ID>` builds a signed Digits Touch with your development profiles. Then `python3 Tools/stage-touch-development.py` stages it in `DigitsDriver/Packaging/TouchDevelopment`.
- `Tools/build-app.sh` and `Tools/build-installer.sh` build signed copies of the app and the installer.

The Digits app embeds that staged, signed Digits Touch, so stage it before you build the app. The staged copy isn't included here because its provisioning profiles list the registered test Macs.

The scripts are set up for my team ID (`PZFJJ4L6SD`). Replace it with yours in `build-app.sh`, `build-installer.sh`, `stage-touch-development.py` and `verify-touch-development.py`.

The driver and Touch scripts use Xcode at `/Applications/Xcode-beta.app`. For `build-driver.sh` and `build-touch.sh`, set `DEVELOPER_DIR` to use another copy. The app and installer scripts use your selected Xcode. Building never installs, loads or activates anything.

The installer build repackages my frozen release; it does not rebuild the drivers. Before bundling, `Tools/prepare-installer-payloads.py` checks the hashes of two components:

- the Digits Driver 0.2.4 package from the release ZIP, expected in `Releases/MacOS-27.3/Components` (or pass `--release-directory`)
- the signed Digits Touch 0.1.6 extension

### Looking at raw touch reports

With Digits installed and the Edge connected, run this from this folder:

```sh
sudo /bin/sh Testing/capture-driver.sh
```

Wait for `READY`, touch the screen, then press **Ctrl-C**. It only listens: nothing is loaded, reset or sent to the panel. Each run is saved under `Results/`, with the full `capture.pcap`, decoded `reports.txt` and a `summary.json`. To decode a saved capture again later, run:

```sh
python3 Testing/read-driver-reports.py --input <capture.pcap> --output <empty-folder>
```

## Limits

- Tested on one Mac, one Edge and one macOS build. Other Macs, macOS versions, ports and touch controllers are untested, and the driver's checks will refuse most of them.
- The FileVault unlock screen appears before these drivers load, so Digits doesn't work there. Touch at the login window, and every sleep, wake and cold-boot sequence, are untested.
- Digits Driver depends on private details of Apple's USB controller implementation, which is why it is pinned to one exact kernel. It is not a public-API driver.
- Nothing here is notarized or approved by Apple.

Digits is an independent project. It is not affiliated with or endorsed by Corsair or Apple.
