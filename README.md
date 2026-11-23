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

Touch reports go from USB to DriverKit to macOS. They never pass through the app, a socket or a helper process. Your display choice is saved on your Mac in `/Library/Application Support/Digits/DigitsDisplayBinding.plist`. No display ID is built into the source.

## Requirements

Digits is locked to the exact setup it was built for. Matching only some of this list is not enough.

- **Display:** a Corsair Xeneon Edge whose touch controller identifies as USB `27C0:0859`, revision `0150`.
- **Mac:** Apple silicon with the `AppleT8142USBXHCI` USB controller, with the Edge plugged into the tested port (USB route `0x00140000`).
- **macOS:** the driver is generated for the exact kernel you run, from your Mac's own kernel collection; see [Build](#3-build). Digits was tested on macOS 27.3 with Darwin 27.3.0 built October 30, 2026 (`xnu-13432.60.57~99/RELEASE_ARM64_T6050`), and the committed table is for that kernel. Check yours with `uname -v`.
- **Security settings:** SIP disabled, **Permissive Security**, and third-party kernel extensions allowed. Reduced Security is not enough.
- **Signing:** your own Apple Developer team, with DriverKit development provisioning for the Mac you install on.
- **Tools:** Xcode 27 with the macOS 27 SDK, [XcodeGen](https://github.com/yonaskolb/XcodeGen) and Python 3.
- **A backup** you know how to restore.

## Install

There are no prebuilt releases. Digits Driver is compiled against a table taken from one exact macOS kernel, so a build only runs on the macOS build it was made for. You compile Digits on your own Mac and compile it again after every macOS update.

### 1. Prepare macOS security (once)

Skip this step if your Mac is already set up.

1. Shut down. Hold the power button until the startup options appear, then choose **Options → Continue** to enter Recovery.
2. Open **Utilities → Terminal** and run:

   ```sh
   csrutil disable
   bputil -n -k
   ```

3. Restart into macOS.

`bputil -n -k` selects Permissive Security and allows kernel extensions. Nothing in this project changes these settings for you.

### 2. Put in your team ID

Wherever the source says `YOUR_TEAM_ID`, replace it with your Apple Developer team ID. Until you do, the build and the installer's signature checks fail on purpose. This command lists every place:

```sh
grep -rl YOUR_TEAM_ID .
```

They are:
- **Build and staging scripts:** `Tools/build-app.sh`, `Tools/build-installer.sh`, `Tools/stage-touch-development.py` and `Tools/verify-touch-development.py`.
- **Code-signing requirements:** `DigitsApp/Source/Installer/DigitsInstallerHostIsValid.m` and `DigitsInstaller/Backend/Common/DigitsInstallerVerifyCode.m`. These make the app and installer trust only code signed by your team.

### 3. Build

Run these from this folder, in order:

```sh
python3 DigitsDriver/regenerate-kernel-table.py    # controller table for your running kernel
sh Tools/build-driver.sh                           # Digits Driver and digits-driver-ctl
sh Tools/package-driver.sh                         # Digits Driver installer package
sh Tools/build-touch-development.sh YOUR_TEAM_ID   # Digits Touch, signed with your team
python3 Tools/stage-touch-development.py           # stage the signed Digits Touch for the app
sh Tools/build-installer.sh                        # Digits app and Digits Installer
```

The first command fits Digits Driver to your kernel; [After a macOS update](#after-a-macos-update) explains what it checks. If it stops, don't build: your kernel needs the driver ported first.

The result is `.build/DigitsInstaller/Build/Products/Debug/Digits Installer.app`.

Building never installs, loads or activates anything. Build output goes to `.build/`, `BuildReports/`, `DigitsDriver/Packaging/` and `Releases/`, which git ignores. The staging step won't overwrite an earlier one, so delete `DigitsDriver/Packaging/TouchDevelopment` before you stage again.

### 4. Run the installer

Keep the Edge connected to the same port the whole time.

1. Open **Digits Installer.app** from the build folder.
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

### After a macOS update

Digits Driver's controller table, [PinnedControllerTable.generated.hpp](DigitsDriver/PinnedControllerTable.generated.hpp), comes from one exact kernel collection. The driver refuses to arm on any other kernel, so multitouch stops after a macOS update until you rebuild:

1. Run `python3 DigitsDriver/regenerate-kernel-table.py`.
2. Repeat the rest of [Build](#3-build).
3. Run the new installer.

[regenerate-kernel-table.py](DigitsDriver/regenerate-kernel-table.py) reads the active boot kernel collection from the Preboot volume as an ordinary file. It never installs, loads or arms anything. It unwraps and decompresses the collection, then confirms it is the running kernel. Before changing anything, it checks that the kernel still matches what the driver relies on:
- **Controller vtable:** `AppleT8142USBXHCI`'s vtable has the 439 virtual functions the driver is compiled for.
- **Factory slots:** the two device-factory slots it hooks, `0x948` and `0x958`, are unchanged.
- **Vptr signing:** the controller still signs its vtable pointer with the discriminator the driver uses, `0xcda1`.
- **Request slot:** `IOUSBHostDevice`'s request method is still at the slot the driver overrides, `0xb68`.

If all checks pass, it rewrites the table and moves every exact-kernel check in the project to the new kernel:
- the driver package scripts
- the installer
- the app's maintenance tool
- the remaining scripts

If any check fails, it changes nothing and says which one. That means Apple changed the controller, and Digits Driver needs porting before it can run on that kernel. Its working files go to `.build/KernelTable`. `--check` confirms the committed table matches your kernel without changing anything.

## What's included

This folder is the complete source:

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
| [DigitsDriver](DigitsDriver/) | Digits Driver: kernel extension source, kernel-table regeneration tool, control tool, standalone build scripts and package scripts |
| [DigitsTouch](DigitsTouch/) | Digits Touch: USB transport, HID touchscreen and user client, plus a small standalone host app that activates it |
| [DigitsInstaller](DigitsInstaller/) | Digits Installer: interface, backend and its maintenance tool |
| [Testing](Testing/) | Passive touch-report capture and status tools |
| [Tools](Tools/) | Build, package and install scripts |
| [Xcode](Xcode/), [project.json](project.json), [Digits.xcodeproj](Digits.xcodeproj/) | The Xcode project and the XcodeGen spec it is generated from |

### Building in Xcode

You can also open `Digits.xcodeproj` in Xcode 27. The shared schemes are:

- **Digits**
- **Digits Installer**
- **Digits Driver**
- **Digits Driver Control**
- **Digits Touch**
- **Digits Touch DEXT**
- **Digits Maintenance**
- **Digits Installer Maintenance**

The Digits app embeds the staged, signed Digits Touch, so run step 3's staging first. The driver and Touch scripts use Xcode at `/Applications/Xcode-beta.app`. For `build-driver.sh` and `build-touch.sh`, set `DEVELOPER_DIR` to use another copy.

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

- Tested on one Mac, one Edge and macOS 27.3. Other Macs, ports and touch controllers are untested, and the driver's checks will refuse most of them.
- The FileVault unlock screen appears before these drivers load, so Digits doesn't work there. Touch at the login window, and every sleep, wake and cold-boot sequence, are untested.
- Digits Driver depends on private details of Apple's USB controller implementation, which is why it is tied to one exact kernel. It is not a public-API driver.
- Nothing here is notarized or approved by Apple.

Digits is an independent project. It is not affiliated with or endorsed by Corsair or Apple.
