# ZeroHub

**Use your USB devices from across the room — wirelessly, for free.**

ZeroHub lets you plug USB devices (game controllers, webcams, storage drives, etc.) into a tiny Raspberry Pi computer, and they show up on your Windows PC automatically over WiFi. No wires running across your room, no monthly fees, no fuss.

No commercial software or subscriptions required — completely free and open-source.

---

## What You'll Need

Before starting, make sure you have:

| Item | Why | Approx. Cost |
|------|-----|-------------|
| **Raspberry Pi** (any model — Zero W, Zero 2 W, 3, 4, 5) | The tiny computer that hosts your USB devices | $10–60 |
| **Micro SD card** (8GB or larger) | Storage for the Pi's operating system | $5–10 |
| **USB power supply** for the Pi | Powers the Pi (micro-USB for Zero/Zero 2 W, USB-C for Pi 4/5) | $8–15 |
| **USB hub** (if using Pi Zero) | The Pi Zero only has one USB port, so you need a hub to connect devices | $5–15 |
| **A Windows PC** on the same WiFi network | Where your USB devices will appear | — |

> **Which Pi should I buy?** The Pi Zero W ($10) works great and is the cheapest option. It's slow to boot (~60 seconds) but works perfectly once it's up. A Pi Zero 2 W ($15) boots faster. Any Pi with WiFi will work.

---

## Setup Guide

### Part 1: Set Up Your Raspberry Pi (one-time, ~15 minutes)

If your Pi is brand new, you need to install an operating system on it first.

**Step 1 — Download Raspberry Pi Imager**

On your Windows PC, go to [raspberrypi.com/software](https://www.raspberrypi.com/software/) and download **Raspberry Pi Imager**. Install and open it.

**Step 2 — Flash the SD card**

1. Insert your micro SD card into your PC (you may need an adapter)
2. In Raspberry Pi Imager:
   - **Device:** Select your Pi model
   - **Operating System:** Select **Raspberry Pi OS Lite (64-bit)** — if you have a Pi Zero W (not Zero 2 W), choose **Raspberry Pi OS Lite (32-bit)** instead
   - **Storage:** Select your SD card
3. Click **Next**
4. When asked **"Would you like to apply OS customisation settings?"**, click **Edit Settings** and configure:
   - **Set hostname:** `zerohub`
   - **Set username and password:** Pick a username (default: `pi`) and a password you'll remember
   - **Configure wireless LAN:** Enter your WiFi name and password
   - **Set locale settings:** Choose your timezone
   - Switch to the **Services** tab and check **Enable SSH** → **Use password authentication**
5. Click **Save**, then **Yes** to apply, then **Yes** to write
6. Wait for it to finish, then eject the SD card

**Step 3 — Boot the Pi**

1. Put the SD card into your Pi
2. If using a Pi Zero with a USB hub: connect the hub to the Pi's USB data port (the one closer to the center of the board, **not** the one on the edge — that's power only)
3. Plug in the Pi's power supply
4. Wait 1–2 minutes for it to boot and connect to WiFi

**Step 4 — Find your Pi on the network**

On your Windows PC, open **Command Prompt** (press `Win+R`, type `cmd`, press Enter) and type:

```
ping zerohub.local
```

If it responds, you'll see your Pi's IP address (something like `192.168.0.55`). Write this down — you'll need it.

> **Not responding?** Wait another minute and try again. If it still doesn't work, log into your router's admin page to find the Pi's IP address, or try `ping zerohub` without `.local`.

---

### Part 2: Install ZeroHub on the Pi (~5 minutes)

**Step 1 — Connect to your Pi**

On your Windows PC, open **Command Prompt** and type:

```
ssh pi@zerohub.local
```

(Replace `pi` with whatever username you chose in the Imager settings.)

Type `yes` if asked about fingerprints, then enter your password. You should now see a command line on the Pi.

**Step 2 — Download and run the installer**

Type these commands one at a time:

```bash
sudo apt install -y git
git clone https://github.com/Pennderin/ZeroHub.git
cd ZeroHub/pi
sudo bash install.sh
```

When asked for your **Windows PC's IP address**, enter it. To find your PC's IP: on your PC, open Command Prompt and type `ipconfig` — look for **IPv4 Address** under your WiFi adapter (something like `192.168.0.74`).

The installer does everything automatically. When it says "Installation Complete", you're done with the Pi.

---

### Part 3: Install ZeroHub on Windows (~5 minutes)

**Step 1 — Install the USB/IP driver**

1. Go to [github.com/vadimgrn/usbip-win2/releases](https://github.com/vadimgrn/usbip-win2/releases)
2. Download the latest `.msi` installer (the one that says "attestation signed" if available — this means no extra steps needed)
3. Run the installer and follow the prompts
4. **If prompted about "test signing":** Some versions require you to open Command Prompt as Administrator and run `bcdedit.exe /set testsigning on`, then restart your PC. Versions with "attestation signed" or "Microsoft-signed" drivers do not need this.

**Step 2 — Install ZeroHub listener**

1. Open **PowerShell as Administrator** (right-click the Start button → "Windows PowerShell (Admin)" or "Terminal (Admin)")
2. Type these commands:

```powershell
git clone https://github.com/Pennderin/ZeroHub.git $env:TEMP\ZeroHub
cd $env:TEMP\ZeroHub\windows
.\install.ps1
```

3. When asked for your **Raspberry Pi's IP address**, enter the IP you found earlier (e.g., `192.168.0.55`)

That's it! The installer sets everything up to run automatically and invisibly in the background.

---

### Part 4: Use It

**Plug any USB device into the Pi's USB hub.** Within about 8 seconds, it will appear on your Windows PC as if it were plugged in directly.

Unplug it from the Pi, and it disappears from the PC.

That's all there is to it. It works automatically every time you turn on your PC and Pi.

---

## Tested Devices

| Device | Status | Notes |
|--------|--------|-------|
| PS5 DualSense Controller | ✅ Working | Full support — rumble, haptics, touchpad, motion sensors |
| USB Storage Devices | ✅ Working | Flash drives, external HDDs |

Tested another device? [Open an issue](https://github.com/Pennderin/ZeroHub/issues) to let us know!

---

## Troubleshooting

**"My device isn't showing up on the PC"**

1. Make sure both the Pi and PC are on the same WiFi network
2. On the Pi (via SSH), run: `cat /var/log/usbip-event.log` — you should see entries when you plug/unplug
3. On the PC, open PowerShell and run: `Get-Content ~\zerohub-listener.log -Tail 20`
4. Try unplugging and re-plugging the USB device

**"I get USB errors when plugging in a device"**

- Try a different USB cable — bad cables are the most common cause
- Try a different port on the hub
- Make sure your hub has enough power for the device

**"It takes a long time after the Pi reboots"**

The Pi (especially the Zero W) takes about 60 seconds to boot. This is normal. Once it's up, devices attach within 8 seconds.

**"How do I check if everything is running?"**

- Pi: `sudo systemctl status usbipd` (should say "active")
- PC: Open Task Manager → look for "powershell" running in the background

---

## Uninstalling

**Pi** (via SSH):
```bash
cd ZeroHub/pi
sudo bash uninstall.sh
```

**Windows** (PowerShell as Administrator):
```powershell
cd $env:TEMP\ZeroHub\windows
.\uninstall.ps1
```

---

## How It Works (Technical)

ZeroHub uses [USB/IP](http://usbip.sourceforge.net/), a Linux kernel module that shares USB devices over a network. On the Windows side, it uses [usbip-win2](https://github.com/vadimgrn/usbip-win2) (free, BSD-licensed, Microsoft-signed drivers).

The magic is in the automation: udev rules on the Pi detect when you plug in a device, automatically bind it to USB/IP, and send a push notification to the Windows listener, which immediately attaches it. No manual commands needed — ever.

The system survives reboots on both sides. If the Pi reboots with a device plugged in, a startup script catches it. If the PC reboots, the listener starts automatically and scans for already-bound devices.

## Credits

- [usbip-win2](https://github.com/vadimgrn/usbip-win2) — USB/IP client for Windows (BSD-2-Clause)
- [USB/IP](http://usbip.sourceforge.net/) — Linux kernel USB device sharing
- Built with [Claude](https://claude.ai) by Anthropic

## License

MIT — see [LICENSE](LICENSE)
