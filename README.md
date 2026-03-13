# ZeroHub

**Use your USB devices from across the room — wirelessly, for free.**

ZeroHub lets you plug USB devices (game controllers, webcams, keyboards, mice, etc.) into a tiny Raspberry Pi, and they show up on your Windows PC automatically over WiFi. No wires across the room, no monthly fees, no fuss.

Completely free and open-source. No commercial software or subscriptions required.

---

## What You'll Need

| Item | Why | Approx. Cost |
|------|-----|-------------|
| **Raspberry Pi** (Zero W, Zero 2 W, 3, 4, or 5) | The tiny computer that hosts your USB devices | $10–60 |
| **Micro SD card** (8GB or larger) | Storage for the Pi's operating system | $5–10 |
| **USB power supply** for the Pi | Powers the Pi (micro-USB for Zero/Zero 2 W, USB-C for Pi 4/5) | $8–15 |
| **USB hub or USB hat** | Lets you connect multiple devices to the Pi | $5–15 |
| **A Windows PC** on the same WiFi network | Where your USB devices will appear | — |

> **Pi Zero and Pi Zero 2 W owners:** These boards only have a single micro-USB OTG port — no full-size USB ports. You'll need a **USB OTG hat** (also called a USB hub hat or expansion board) to add USB-A ports. A regular micro-USB-to-USB-A adapter works for a single device, but a hat with a built-in hub is recommended.
>
> Pi 3, 4, and 5 have built-in USB-A ports and don't need an adapter.

> **Which Pi should I buy?** The Pi Zero W ($10) is the cheapest option. It works perfectly but boots slowly (~60 seconds). The **Pi Zero 2 W ($15) is the best value** — it's 4x faster with a quad-core CPU and boots in ~25 seconds. A Pi 3/4/5 has built-in USB ports and more power, but costs more. Any Pi with WiFi will work.

---

## Important: Operating System Notes

### Recommended: Raspberry Pi OS Lite (32-bit)

**Raspberry Pi OS Lite (32-bit) is the only tested and recommended OS for ZeroHub.** It works reliably on all Pi models.

### ⚠️ DietPi Is Not Supported

DietPi was evaluated during development but **is not recommended**. Testing revealed that DietPi's 64-bit kernel (`6.12.62+rpt-rpi-v8`) has a critical bug in the `usbip_host` kernel module: it kernel panics whenever a USB device is physically unplugged while bound to USB/IP with an active connection. This causes the Pi to crash and become unreachable, requiring a power cycle every time a device is removed. This makes DietPi unusable for ZeroHub's hot-plug workflow.

### ⚠️ 64-bit Kernel Warning

While ZeroHub's installer will work on a 64-bit Raspberry Pi OS install, **we have only fully tested the 32-bit kernel**. The 64-bit kernel builds (`aarch64` / `armv8`) use different kernel module builds, and based on our experience with DietPi's 64-bit kernel crash, there may be unforeseen bugs in 64-bit USB/IP kernel modules that don't appear in the 32-bit (`armv7l`) versions.

**If you want maximum reliability, use the 32-bit image.** If you choose 64-bit and encounter USB/IP crashes or kernel panics on device unplug, switch to 32-bit before reporting bugs.

| Pi Model | Recommended OS |
|----------|---------------|
| **Pi Zero W** | Raspberry Pi OS Lite (32-bit) — only option (ARMv6) |
| **Pi Zero 2 W** | Raspberry Pi OS Lite (32-bit) — tested and stable |
| **Pi 3/4/5** | Raspberry Pi OS Lite (32-bit) — most reliable for USB/IP |

---

## Setup Guide

This guide has two parts:

1. **[Part 1: Set Up Your Raspberry Pi](#part-1-set-up-your-raspberry-pi)** — Install the OS and ZeroHub on your Pi
2. **[Part 2: Set Up Your Windows PC](#part-2-set-up-your-windows-pc)** — Install the USB/IP driver and ZeroHub listener

---

## Part 1: Set Up Your Raspberry Pi

### Step 1 — Download Raspberry Pi Imager

On your Windows PC, go to [raspberrypi.com/software](https://www.raspberrypi.com/software/) and download **Raspberry Pi Imager**. Install and open it.

### Step 2 — Flash the SD Card

1. Insert your micro SD card into your PC (you may need an adapter)
2. In Raspberry Pi Imager:
   - **Device:** Select your Pi model
   - **Operating System:** Select **Raspberry Pi OS (other)** → **Raspberry Pi OS Lite (32-bit)**
   - **Storage:** Select your SD card
3. Click **Next**
4. When asked **"Would you like to apply OS customisation settings?"**, click **Edit Settings** and configure:
   - **Set hostname:** `zerohub`
   - **Set username and password:** Username `pi`, pick a password you'll remember
   - **Configure wireless LAN:** Enter your WiFi name (SSID) and password
   - **Set locale settings:** Your timezone and keyboard layout
   - Go to the **Services** tab and check **Enable SSH** → **Use password authentication**
5. Click **Save**, then **Yes** to apply settings
6. Click **Yes** to write (this will erase the SD card)
7. Wait for it to finish, then eject the SD card

### Step 3 — Boot the Pi and Find Its IP

1. Put the SD card in your Pi
2. Plug in the USB hub/hat (if you have one)
3. Power on the Pi
4. Wait 30–90 seconds for it to boot and connect to WiFi
5. Find the Pi's IP address — check your router's admin page (usually 192.168.0.1 or 192.168.1.1) and look for a device named `zerohub`

> **Can't find it?** See the [Finding IP Addresses](#finding-ip-addresses) section below for more options.

### Step 4 — Connect via SSH

On your Windows PC, open **PowerShell** or **Command Prompt** and run:

```
ssh pi@<PI_IP_ADDRESS>
```

Replace `<PI_IP_ADDRESS>` with the IP you found (e.g., `ssh pi@192.168.0.55`). Enter your password when prompted. Type `yes` if asked about the fingerprint.

### Step 5 — Install ZeroHub

Run this single command on the Pi (replace `YOUR_PC_IP` with your Windows PC's IP address):

```bash
curl -sL https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/install.sh | sudo bash -s YOUR_PC_IP
```

For example, if your PC's IP is `192.168.0.74`:

```bash
curl -sL https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/install.sh | sudo bash -s 192.168.0.74
```

> **How to find your PC's IP:** On your Windows PC, open PowerShell and run `ipconfig`. Look for the IPv4 address under your WiFi adapter (usually starts with `192.168.`).

### Step 6 — Reboot the Pi

```bash
sudo reboot
```

Your Pi is ready! Move on to [Part 2: Set Up Your Windows PC](#part-2-set-up-your-windows-pc).

> **Tip:** Consider assigning your Pi a **static IP** in your router settings so it doesn't change. Look for "DHCP Reservation" or "Address Reservation" in your router's admin page. This way you won't need to update ZeroHub if the Pi reboots with a different IP.

---

## Part 2: Set Up Your Windows PC

### Step 1 — Install the USB/IP Driver

ZeroHub uses `usbip-win2` to make USB devices from the Pi appear on your PC.

1. Go to [github.com/vadimgrn/usbip-win2/releases](https://github.com/vadimgrn/usbip-win2/releases)
2. Download the latest **`usbip-win2_X.X.X.X_x64_Release.exe`** installer
3. Run the installer
4. If Windows SmartScreen shows "Windows protected your PC", click **More info** → **Run anyway**
5. Follow the installer prompts — click **Install** when asked about the driver
6. If asked about an unsigned driver, click **Install this driver software anyway**
7. **Restart your PC** after installation

> **Secure Boot issues?** If the driver fails to install, you may need to temporarily disable Secure Boot in your BIOS. Search for your PC/motherboard model + "disable Secure Boot" for instructions. You can re-enable it after the driver is installed.

### Step 2 — Install ZeroHub Listener

1. Download or clone this repository (or download from [Releases](https://github.com/Penderrin-Projects/ZeroHub/releases/latest))
2. Open the `windows` folder
3. **Double-click `install.bat`** — it will request admin privileges automatically
4. Enter your Pi's IP address when prompted
5. The installer will:
   - Install the listener scripts to `C:\Program Files\ZeroHub\`
   - Create a data directory at `C:\ProgramData\ZeroHub\` for logs
   - Create a scheduled task that starts the listener at login
   - Configure a firewall rule

> **Tray App (Recommended):** The tray app gives you a system tray icon with device status, custom popup notifications, settings, and service controls. Download `ZeroHub.Companion.exe` from the [latest release](https://github.com/Penderrin-Projects/ZeroHub/releases/latest) and place it in `C:\Program Files\ZeroHub\`. Then add a shortcut to your Startup folder so it launches at login. Alternatively, if you have [Node.js](https://nodejs.org) installed, you can build it yourself from the `windows/tray-app` directory.

### Step 3 — Test It!

1. Make sure your Pi is powered on with USB devices plugged in
2. You should see a notification popup when devices connect
3. The devices will appear in Windows as if they were plugged in directly

---

## How It Works

```
┌─────────────────┐         WiFi          ┌──────────────────┐
│                 │  ◄──────────────────►  │                  │
│  Raspberry Pi   │     USB/IP Protocol    │   Windows PC     │
│                 │                        │                  │
│  USB Hub ─┬─ 🎮 │                        │  🎮 Game Pad     │
│           ├─ ⌨️  │                        │  ⌨️  Keyboard    │
│           └─ 🖱️  │                        │  🖱️  Mouse       │
└─────────────────┘                        └──────────────────┘
```

1. **Pi boots** → Binds all connected USB devices to the USB/IP driver
2. **Pi connects to WiFi** → Announces itself to the PC listener
3. **PC listener receives announcement** → Attaches each device over the network
4. **Devices appear on PC** → Windows sees them as locally connected USB devices
5. **Hot-plug supported** → Plug/unplug devices from the Pi anytime

---

## System Tray App

After login, the ZeroHub Companion tray app shows a blue **Z** icon in your system tray. Right-click for:

- **Connected Devices** — See which USB devices are currently connected
- **Settings** — Change the Pi's IP address
- **Stop/Start/Restart Service** — Control the background listener
- **Open Log** — View the event log for troubleshooting
- **Exit Tray** — Close the tray app (the background service keeps running independently)

The tray app is read-only — it polls `usbip port` every 5 seconds to show real device state. Closing or crashing the tray app has no effect on the listener service.

---

## File Locations

### Windows

| What | Path |
|------|------|
| Listener & scripts | `C:\Program Files\ZeroHub\` |
| Tray app EXE | `C:\Program Files\ZeroHub\ZeroHub Companion.exe` |
| Log file | `C:\ProgramData\ZeroHub\zerohub-listener.log` |
| Scheduled task | "ZeroHub Auto-Attach Listener" (Task Scheduler) |

### Raspberry Pi

| What | Path |
|------|------|
| Event handler | `/usr/local/bin/usbip-event.sh` |
| Boot bind script | `/usr/local/bin/usbip-startup.sh` |
| Announce script | `/usr/local/bin/zerohub-announce.sh` |
| udev rules | `/etc/udev/rules.d/99-usbip-autobind.rules` |
| Event log | `/var/log/usbip-event.log` |

---

## Finding IP Addresses

You'll need two IP addresses during setup: your **Pi's IP** and your **PC's IP**. Here's how to find them.

### Your PC's IP Address

1. Press **Win + R**, type `cmd`, press Enter
2. Type `ipconfig` and press Enter
3. Look for **Wireless LAN adapter Wi-Fi** (or **Ethernet adapter** if wired)
4. Find the line that says **IPv4 Address** — that's your PC's IP (e.g., `192.168.0.74`)

### Your Pi's IP Address

**Method 1 — Check your router** (easiest):
1. Open a browser and go to your router's admin page (usually `192.168.0.1` or `192.168.1.1`)
2. Look for a "Connected Devices" or "DHCP Clients" list
3. Find the device named `zerohub`

**Method 2 — Use a network scanner:**
1. Download [Advanced IP Scanner](https://www.advanced-ip-scanner.com/) (free)
2. Click "Scan" — it will find all devices on your network
3. Look for the Pi's hostname

**Method 3 — From the Pi itself** (if you have a monitor connected):
```bash
hostname -I
```

> **Tip:** Once you know your Pi's IP, consider assigning it a **static IP** in your router settings so it doesn't change. Look for "DHCP Reservation" or "Static IP" in your router's admin page.

---

## Troubleshooting

**Devices not showing up?**
- Make sure both the Pi and PC are on the same WiFi network
- Check that the Pi's IP address is correct in the listener config
- Try restarting the Pi (unplug and re-plug power)
- Check the log file: `C:\ProgramData\ZeroHub\zerohub-listener.log`

**Pi can't connect to WiFi?**
- Double-check your WiFi name and password in the Pi's config
- WiFi names with special characters (spaces, dots, `!`) can cause issues — try a simpler network name or a mobile hotspot for initial setup
- Make sure you're using 2.4GHz WiFi (the Pi Zero W and Zero 2 W don't support 5GHz)

**"Connection timed out" errors in the log?**
- The Pi might have lost WiFi — power cycle it
- Check if the Pi's firewall is blocking connections (run `sudo iptables -F` on the Pi)

**Devices disconnect randomly?**
- WiFi power management may be turning off the radio. On the Pi, run:
  ```bash
  sudo iw dev wlan0 set power_save off
  ```
- For a permanent fix, add a boot script or cron job to disable it

**Kernel panic / Pi crashes when unplugging a device?**
- This is a known issue with **64-bit kernels** and the `usbip_host` kernel module. Switch to **Raspberry Pi OS Lite (32-bit)** — see [Important: Operating System Notes](#important-operating-system-notes) above.

**How to change the Pi's IP address?**
- Right-click the ZeroHub tray icon → Settings → enter the new IP → Save

---

## Optimizing Boot Time (Optional)

For faster boot on your Pi, you can disable unnecessary services:

```bash
# Disable services not needed for ZeroHub
sudo systemctl disable --now bluetooth hciuart avahi-daemon ModemManager

# Reduce GPU memory and disable splash screen
echo 'gpu_mem=16' | sudo tee -a /boot/config.txt
echo 'disable_splash=1' | sudo tee -a /boot/config.txt
echo 'boot_delay=0' | sudo tee -a /boot/config.txt

# Disable WiFi power saving
sudo iw dev wlan0 set power_save off
```

---

## Uninstalling

**On the Pi:**
```bash
curl -sL https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/uninstall.sh | sudo bash
```

**On the PC:**
Double-click `uninstall.bat` in the `windows` folder, or run PowerShell as Administrator:
```powershell
powershell -ExecutionPolicy Bypass -File path\to\ZeroHub\windows\uninstall.ps1
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.
