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

## Setup Guide

This guide has two parts:

1. **[Part 1: Set Up Your Raspberry Pi](#part-1-set-up-your-raspberry-pi)** — Install the OS and ZeroHub on your Pi
2. **[Part 2: Set Up Your Windows PC](#part-2-set-up-your-windows-pc)** — Install the USB/IP driver and ZeroHub listener

### Which OS Should I Use?

| Pi Model | Recommended OS | Why |
|----------|---------------|-----|
| **Pi Zero W** | Raspberry Pi OS Lite (32-bit) | Only supports 32-bit (ARMv6) |
| **Pi Zero 2 W** | DietPi (64-bit ARMv8) or Pi OS Lite (64-bit) | DietPi is lighter and boots faster |
| **Pi 3/4/5** | Raspberry Pi OS Lite (64-bit) | Full support, easy setup |

---

## Part 1: Set Up Your Raspberry Pi

Choose your path based on which OS you want to use:

- **[Option A: Raspberry Pi OS Lite](#option-a-raspberry-pi-os-lite)** — Easiest, works on all Pi models
- **[Option B: DietPi](#option-b-dietpi)** — Lighter and faster, recommended for Pi Zero 2 W

---

### Option A: Raspberry Pi OS Lite

Best for: Pi Zero W, Pi 3, Pi 4, Pi 5, or anyone who wants the simplest setup.

**Step 1 — Download Raspberry Pi Imager**

On your Windows PC, go to [raspberrypi.com/software](https://www.raspberrypi.com/software/) and download **Raspberry Pi Imager**. Install and open it.

**Step 2 — Flash the SD Card**

1. Insert your micro SD card into your PC (you may need an adapter)
2. In Raspberry Pi Imager:
   - **Device:** Select your Pi model
   - **Operating System:** Select **Raspberry Pi OS Lite (64-bit)** — if you have a **Pi Zero W** (not Zero 2 W), choose **Raspberry Pi OS Lite (32-bit)** instead
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

**Step 3 — Boot the Pi and Find Its IP**

1. Put the SD card in your Pi
2. Plug in the USB hub/hat (if you have one)
3. Power on the Pi
4. Wait 30–90 seconds for it to boot and connect to WiFi
5. Find the Pi's IP address — check your router's admin page (usually 192.168.0.1 or 192.168.1.1) and look for a device named `zerohub`

**Step 4 — Connect via SSH**

On your Windows PC, open **PowerShell** or **Command Prompt** and run:

```
ssh pi@<PI_IP_ADDRESS>
```

Replace `<PI_IP_ADDRESS>` with the IP you found (e.g., `ssh pi@192.168.0.55`). Enter your password when prompted. Type `yes` if asked about the fingerprint.

**Step 5 — Install ZeroHub**

Run this single command on the Pi (replace `YOUR_PC_IP` with your Windows PC's IP address):

```bash
curl -sL https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/install.sh | sudo bash -s YOUR_PC_IP
```

For example, if your PC's IP is `192.168.0.74`:

```bash
curl -sL https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/install.sh | sudo bash -s 192.168.0.74
```

> **How to find your PC's IP:** On your Windows PC, open PowerShell and run `ipconfig`. Look for the IPv4 address under your WiFi adapter (usually starts with `192.168.`).

**Step 6 — Reboot the Pi**

```bash
sudo reboot
```

Your Pi is ready! Move on to [Part 2: Set Up Your Windows PC](#part-2-set-up-your-windows-pc).

---

### Option B: DietPi

Best for: Pi Zero 2 W. Lighter, faster boot, more efficient. Slightly more manual setup.

**Step 1 — Download DietPi**

Go to [dietpi.com](https://dietpi.com/#download) and download the image for your Pi:

| Pi Model | Image |
|----------|-------|
| Pi Zero 2 W | `DietPi_RPi234-ARMv8-Bookworm.img.xz` |
| Pi 3 | `DietPi_RPi234-ARMv8-Bookworm.img.xz` |
| Pi 4/5 | `DietPi_RPi45-ARMv8-Bookworm.img.xz` |

> **Pi Zero W:** DietPi doesn't have great ARMv6 support. Use [Option A (Pi OS Lite)](#option-a-raspberry-pi-os-lite) instead.

**Step 2 — Flash the SD Card**

1. Open Raspberry Pi Imager
2. Click **Choose OS** → scroll down → **Use custom** → select the `.img.xz` file you downloaded
3. Click **Choose Storage** → select your SD card
4. Click **Next** → **No** (don't customize — DietPi has its own config)
5. Click **Yes** to write and wait for it to finish

**Do NOT eject yet** — you need to configure WiFi first.

**Step 3 — Configure WiFi**

The SD card should have a boot partition visible in File Explorer (usually drive letter `G:` or similar). Open it and edit two files:

**Edit `dietpi-wifi.txt`:**

Open it with Notepad and fill in your WiFi details:

```
aWIFI_SSID[0]='YourWiFiName'
aWIFI_KEY[0]='YourWiFiPassword'
aWIFI_KEYMGR[0]='WPA-PSK'
```

> **Important:** If your WiFi name has special characters (spaces, dots, exclamation marks), this may not work. In that case, use a simple hotspot or secondary network for initial setup, then switch to your main WiFi later.

**Edit `dietpi.txt`:**

Find and change these settings:

```
AUTO_SETUP_NET_WIFI_ENABLED=1          (change from 0 to 1)
AUTO_SETUP_NET_ETHERNET_ENABLED=0      (change from 1 to 0)
AUTO_SETUP_HEADLESS=1                  (change from 0 to 1)
AUTO_SETUP_AUTOMATED=1                 (change from 0 to 1)
AUTO_SETUP_NET_HOSTNAME=ZeroHub        (change from DietPi)
AUTO_SETUP_GLOBAL_PASSWORD=zerohub55   (change from dietpi — pick your own password)
AUTO_SETUP_SSH_SERVER_INDEX=-2         (change from -1 — installs OpenSSH instead of Dropbear)
```

Optionally, add your SSH public key for key-based authentication (find the line starting with `#AUTO_SETUP_SSH_PUBKEY=` and uncomment it, replacing the example key with yours).

**Step 4 — Eject and Boot**

1. Safely eject the SD card
2. Put it in your Pi
3. Plug in the USB hub/hat
4. Power on the Pi
5. Wait 2–3 minutes for the first boot (DietPi does initial setup — this only happens once)
6. Find the Pi's IP address from your router's admin page

**Step 5 — Connect via SSH**

```
ssh root@<PI_IP_ADDRESS>
```

Password is what you set in `dietpi.txt` (default: `zerohub55`).

**Step 6 — Install ZeroHub**

```bash
curl -sL https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/install.sh | bash -s YOUR_PC_IP
```

Replace `YOUR_PC_IP` with your Windows PC's IP address.

**Step 7 — Reboot**

```bash
reboot
```

Your Pi is ready! Move on to [Part 2: Set Up Your Windows PC](#part-2-set-up-your-windows-pc).

---

## Part 2: Set Up Your Windows PC

**Step 1 — Install the USB/IP Driver**

ZeroHub uses `usbip-win2` to make USB devices from the Pi appear on your PC.

1. Go to [github.com/cezuni/usbip-win2/releases](https://github.com/cezuni/usbip-win2/releases)
2. Download the latest `usbip-win2_vX.X.X.X.msi` file
3. Double-click to run the installer
4. If Windows SmartScreen shows "Windows protected your PC", click **More info** → **Run anyway**
5. Follow the installer prompts — click **Install** when asked about the driver
6. If asked about an unsigned driver, click **Install this driver software anyway**
7. **Restart your PC** after installation

> **Secure Boot issues?** If the driver fails to install, you may need to temporarily disable Secure Boot in your BIOS. Search for your PC/motherboard model + "disable Secure Boot" for instructions. You can re-enable it after the driver is installed.

> **Still having trouble?** Try running the `.msi` installer from an elevated Command Prompt:
> ```
> msiexec /i usbip-win2_vX.X.X.X.msi
> ```

**Step 2 — Install ZeroHub Listener**

1. Download or clone this repository (or download from [Releases](https://github.com/Penderrin-Projects/ZeroHub/releases/latest))
2. Open the `windows` folder
3. **Double-click `install.bat`** — it will request admin privileges automatically
4. Enter your Pi's IP address when prompted
6. The installer will:
   - Install the listener scripts
   - Create a boot service (runs before login)
   - Build and install the system tray app (if Node.js is available)
   - Create a login startup shortcut for the tray app

> **Tray App (Recommended):** The tray app gives you a system tray icon with device status, custom popup notifications, settings, and service controls. The installer will build it automatically if [Node.js](https://nodejs.org) is installed. **If you don't have Node.js**, download `ZeroHub.Listener.exe` from the [latest release](https://github.com/Penderrin-Projects/ZeroHub/releases/latest) and place it in `C:\Program Files\ZeroHub\`. The installer will find it and set it up for you.

**Step 3 — Test It!**

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

After login, the ZeroHub tray app shows a blue **Z** icon in your system tray. Right-click for:

- **Connected Devices** — See which USB devices are currently connected
- **Settings** — Change the Pi's IP address
- **Stop/Start/Restart Service** — Control the background listener
- **Open Log** — View the event log for troubleshooting
- **Exit Tray** — Close the tray app (the background service keeps running)

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
3. Find the device named `zerohub` (or `DietPi` if you haven't changed the hostname yet)

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
- Check the log file: `C:\Users\<you>\zerohub-listener.log`

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

**How to change the Pi's IP address?**
- Right-click the ZeroHub tray icon → Settings → enter the new IP → Save
- Or edit `%APPDATA%\zerohub-listener\config.json`

---

## Optimizing Boot Time (Optional)

For faster boot on your Pi, you can disable unnecessary services:

```bash
# Disable services not needed for ZeroHub
sudo systemctl disable --now console-setup.service keyboard-setup.service getty@tty1.service

# Disable Bluetooth (if not needed)
echo 'dtoverlay=disable-bt' | sudo tee -a /boot/config.txt
echo 'gpu_mem=16' | sudo tee -a /boot/config.txt
echo 'disable_splash=1' | sudo tee -a /boot/config.txt
echo 'boot_delay=0' | sudo tee -a /boot/config.txt

# Disable WiFi power saving
sudo iw dev wlan0 set power_save off
```

With these optimizations, a Pi Zero 2 W with DietPi can boot and have devices ready in under 40 seconds.

---

## Uninstalling

**On the Pi:**
```bash
curl -sL https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/uninstall.sh | sudo bash
```

**On the PC:**
Run PowerShell as Administrator:
```powershell
powershell -ExecutionPolicy Bypass -File path\to\ZeroHub\windows\uninstall.ps1
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.
