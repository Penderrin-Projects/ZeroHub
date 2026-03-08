#!/bin/bash
# ZeroHub - Pi USB/IP Server Installer
# Turns a Raspberry Pi into a plug-and-play USB device server
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║           ZeroHub Installer              ║"
echo "║   Free USB/IP Device Server for Pi       ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root: sudo bash install.sh${NC}"
    exit 1
fi

# Check if running on a Pi
if ! grep -qi 'raspberry\|bcm' /proc/cpuinfo 2>/dev/null; then
    echo -e "${YELLOW}Warning: This doesn't appear to be a Raspberry Pi. Continuing anyway...${NC}"
fi

# Get PC IP from user
echo ""
read -p "Enter your Windows PC's IP address: " PC_IP

# Validate IP format
if ! echo "$PC_IP" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
    echo -e "${RED}Invalid IP address format.${NC}"
    exit 1
fi

PC_PORT="3241"

echo ""
echo -e "${GREEN}Installing with PC target: ${PC_IP}:${PC_PORT}${NC}"
echo ""

# Step 1: Install packages
echo -e "${CYAN}[1/7] Installing USB/IP packages...${NC}"
apt-get update -qq
apt-get install -y -qq usbip hwdata usbutils curl > /dev/null 2>&1
echo -e "${GREEN}  ✓ Packages installed${NC}"

# Step 2: Install usbipd service
echo -e "${CYAN}[2/7] Configuring USB/IP daemon service...${NC}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "$SCRIPT_DIR/usbipd.service" /etc/systemd/system/usbipd.service
systemctl daemon-reload
systemctl enable usbipd.service > /dev/null 2>&1
systemctl start usbipd.service
echo -e "${GREEN}  ✓ usbipd service installed and started${NC}"

# Step 3: Install event script (with user's PC IP)
echo -e "${CYAN}[3/7] Installing auto-bind event script...${NC}"
sed "s|__PC_IP__|${PC_IP}|g; s|__PC_PORT__|${PC_PORT}|g" "$SCRIPT_DIR/usbip-event.sh.template" > /usr/local/bin/usbip-event.sh
chmod +x /usr/local/bin/usbip-event.sh
echo -e "${GREEN}  ✓ Event script installed${NC}"

# Step 4: Install startup script (with user's PC IP)
echo -e "${CYAN}[4/7] Installing boot-time auto-bind script...${NC}"
sed "s|__PC_IP__|${PC_IP}|g; s|__PC_PORT__|${PC_PORT}|g" "$SCRIPT_DIR/usbip-startup.sh.template" > /usr/local/bin/usbip-startup.sh
chmod +x /usr/local/bin/usbip-startup.sh
echo -e "${GREEN}  ✓ Startup script installed${NC}"

# Step 5: Install udev rules
echo -e "${CYAN}[5/7] Installing udev rules...${NC}"
cp "$SCRIPT_DIR/99-usbip-autobind.rules" /etc/udev/rules.d/99-usbip-autobind.rules
udevadm control --reload-rules
echo -e "${GREEN}  ✓ udev rules installed${NC}"

# Step 6: Install autobind service
echo -e "${CYAN}[6/7] Installing auto-bind boot service...${NC}"
cp "$SCRIPT_DIR/usbip-autobind.service" /etc/systemd/system/usbip-autobind.service
systemctl daemon-reload
systemctl enable usbip-autobind.service > /dev/null 2>&1
echo -e "${GREEN}  ✓ Auto-bind boot service enabled${NC}"

# Step 7: Install network announce script (notifies PC when Pi comes online)
echo -e "${CYAN}[7/8] Installing network announce script...${NC}"
if [ -d /etc/NetworkManager/dispatcher.d ]; then
    sed "s|__PC_IP__|${PC_IP}|g; s|__PC_PORT__|${PC_PORT}|g" "$SCRIPT_DIR/99-zerohub-announce" > /etc/NetworkManager/dispatcher.d/99-zerohub-announce
    chmod +x /etc/NetworkManager/dispatcher.d/99-zerohub-announce
    echo -e "${GREEN}  ✓ Network announce script installed (NetworkManager)${NC}"
else
    echo -e "${YELLOW}  ⚠ NetworkManager not found — skipping announce script${NC}"
    echo -e "${YELLOW}    Pi won't announce itself when reconnecting, but devices will still auto-bind${NC}"
fi

# Step 8: Configure firewall (if active)
echo -e "${CYAN}[8/8] Configuring firewall...${NC}"
if command -v ufw > /dev/null 2>&1 && ufw status | grep -q "active"; then
    ufw allow 3240/tcp comment "ZeroHub USB/IP daemon" > /dev/null 2>&1
    echo -e "${GREEN}  ✓ UFW rule added (TCP 3240 inbound)${NC}"
elif command -v firewall-cmd > /dev/null 2>&1 && systemctl is-active firewalld > /dev/null 2>&1; then
    firewall-cmd --permanent --add-port=3240/tcp > /dev/null 2>&1
    firewall-cmd --reload > /dev/null 2>&1
    echo -e "${GREEN}  ✓ Firewalld rule added (TCP 3240 inbound)${NC}"
else
    echo -e "${GREEN}  ✓ No active firewall detected — no changes needed${NC}"
fi

# Create log file
touch /var/log/usbip-event.log
chmod 666 /var/log/usbip-event.log

# Show summary
PI_IP=$(hostname -I | awk '{print $1}')
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗"
echo -e "║          Installation Complete!           ║"
echo -e "╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Pi IP:         ${GREEN}${PI_IP}${NC}"
echo -e "  PC target:     ${GREEN}${PC_IP}:${PC_PORT}${NC}"
echo -e "  Log file:      /var/log/usbip-event.log"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Run the Windows installer on your PC"
echo -e "  2. Enter this Pi's IP (${PI_IP}) when prompted"
echo -e "  3. Plug a USB device into the Pi — it will appear on your PC automatically"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  sudo systemctl status usbipd          # Check daemon status"
echo -e "  sudo usbip list -l                     # List bound devices"
echo -e "  cat /var/log/usbip-event.log           # View event log"
echo -e "  lsusb                                  # List connected USB devices"
echo ""
