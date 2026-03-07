# ZeroHub

**Turn a Raspberry Pi into a free, plug-and-play USB device server.**

ZeroHub replaces commercial USB-over-IP solutions like VirtualHere ($49+, hardware-locked license) with a fully open-source, self-hosted alternative. Plug a USB device into your Pi — it automatically appears on your Windows PC within seconds. No manual commands, no polling, no subscriptions.

## How It Works

```
USB Device → Pi (USB hub) → WiFi/Ethernet → Windows PC
              ↓                                  ↓
         auto-bind              ← HTTP push →  auto-attach
         (udev + usbip)          notification   (usbip-win2)
```

1. **Plug** a USB device into the Pi's USB hub
2. **udev** detects it and triggers the ZeroHub event script
3. The script **binds** the device to USB/IP and sends an HTTP push notification to your PC
4. The PC listener receives the event and **attaches** the device via USB/IP
5. The device appears natively in Windows — games, drivers, and apps see it as a local USB device

No polling. No manual steps. Event-driven, ~8 seconds end-to-end.

## Features

- **Plug-and-play** — just plug in a USB device and it appears on your PC
- **Survives reboots** — both Pi and PC sides auto-recover
- **Push-based** — no polling; event-driven architecture
- **Zero cost** — entirely open-source software
- **Works with everything** — game controllers (PS5 DualSense tested with full haptics), webcams, storage devices, input devices, etc.
- **Hidden operation** — Windows listener runs invisibly in the background

## Requirements

### Pi Side
- Raspberry Pi (tested on Pi Zero W; any model with USB should work)
- USB hub (if using Pi Zero — it only has one USB port)
- Raspbian/Raspberry Pi OS (Debian-based)
- Network connection (WiFi or Ethernet)

### PC Side
- Windows 10/11 (64-bit)
- [usbip-win2](https://github.com/vadimgrn/usbip-win2/releases) installed (free, BSD-licensed, Microsoft-signed drivers)
- PowerShell 5.1+ (included with Windows)

## Installation

### Step 1: Install usbip-win2 on Windows

Download the latest installer from [usbip-win2 releases](https://github.com/vadimgrn/usbip-win2/releases) and run it. This installs the USB/IP virtual host controller driver and command-line tools.

> **Note:** Releases marked with "attestation signed drivers" do not require test-signing mode. If your release uses test-signed drivers, you'll need to enable test signing: `bcdedit.exe /set testsigning on` (reboot required).

### Step 2: Set Up the Pi

SSH into your Pi and run:

```bash
git clone https://github.com/Pennderin/ZeroHub.git
cd ZeroHub/pi
sudo bash install.sh
```

The installer will:
- Install the `usbip` package and dependencies
- Set up the USB/IP daemon as a systemd service
- Install udev rules for automatic device binding
- Install a boot-time script to handle devices plugged in before startup
- Ask for your Windows PC's IP address

### Step 3: Set Up Windows

Open PowerShell **as Administrator** and run:

```powershell
git clone https://github.com/Pennderin/ZeroHub.git
cd ZeroHub\windows
.\install.ps1
```

The installer will:
- Verify usbip-win2 is installed
- Install the listener script and hidden launcher
- Create a scheduled task that starts at login
- Create a firewall rule for the listener port (TCP 3241)
- Start the listener immediately

### Step 4: Test It

Plug a USB device into the Pi's hub. Within ~8 seconds it should appear on your PC. Check with:

```powershell
& "C:\Program Files\USBip\usbip.exe" port
```

## Troubleshooting

### Device not appearing on PC

1. **Check the Pi event log:**
   ```bash
   cat /var/log/usbip-event.log
   ```
   You should see `add`, `BIND`, and `PUSH sent` entries.

2. **Check the PC listener log:**
   ```powershell
   Get-Content ~\zerohub-listener.log -Tail 20
   ```
   You should see `EVENT: Device added` and `ATTACHING` entries.

3. **Verify the Pi daemon is running:**
   ```bash
   sudo systemctl status usbipd
   ```

4. **Verify the PC can see exported devices:**
   ```powershell
   & "C:\Program Files\USBip\usbip.exe" list -r <PI_IP>
   ```

### USB enumeration errors (error -71)

This means the Pi can't communicate with the USB device at the hardware level. Common causes:
- **Bad USB cable** — try a different cable (this is the most common cause)
- **Insufficient power** — use a powered USB hub
- **Port issue** — try a different port on the hub

### Listener not starting on Windows boot

Check the scheduled task:
```powershell
Get-ScheduledTask -TaskName "ZeroHub Auto-Attach Listener" | Select State
```

If it shows "Disabled", re-enable it:
```powershell
Enable-ScheduledTask -TaskName "ZeroHub Auto-Attach Listener"
```

## Uninstallation

### Pi
```bash
cd ZeroHub/pi
sudo bash uninstall.sh
```

### Windows
Open PowerShell as Administrator:
```powershell
cd ZeroHub\windows
.\uninstall.ps1
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Raspberry Pi                       │
│                                                      │
│  USB Device ──► udev rule ──► usbip-event.sh        │
│                                  │                   │
│                          ┌───────┴────────┐          │
│                          │ usbip bind     │          │
│                          │ HTTP POST ─────┼──────┐   │
│                          └────────────────┘      │   │
│                                                  │   │
│  usbipd (port 3240) ◄───────────────────────┐   │   │
│                                              │   │   │
└──────────────────────────────────────────────┼───┼───┘
                                               │   │
                              USB/IP traffic   │   │ HTTP push
                              (TCP 3240)       │   │ (TCP 3241)
                                               │   │
┌──────────────────────────────────────────────┼───┼───┐
│                  Windows PC                  │   │   │
│                                              │   │   │
│  zerohub-listener.ps1 ◄─────────────────────┼───┘   │
│       │                                      │       │
│       ├──► usbip.exe attach ─────────────────┘       │
│       │                                              │
│  usbip-win2 virtual HCI ──► Device appears natively  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

## Tested Devices

| Device | Status | Notes |
|--------|--------|-------|
| PS5 DualSense Controller | ✅ Working | Full support — rumble, haptics, touchpad, motion sensors |
| USB Storage Devices | ✅ Working | Flash drives, external HDDs |

Have you tested other devices? Open an issue or PR to add to this list!

## Credits

- [usbip-win2](https://github.com/vadimgrn/usbip-win2) by vadimgrn — USB/IP client for Windows (BSD-2-Clause license)
- [USB/IP](http://usbip.sourceforge.net/) — Linux kernel USB/IP implementation
- Built with help from [Claude](https://claude.ai) by Anthropic

## License

MIT License — see [LICENSE](LICENSE) for details.
