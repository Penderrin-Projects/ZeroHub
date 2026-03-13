#!/bin/bash
# ZeroHub - Pi USB/IP Server Installer
# Turns a Raspberry Pi into a plug-and-play USB device server
# Supports: Pi OS (NetworkManager), DietPi (ifupdown), and other Debian-based distros
set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║           ZeroHub Installer              ║"
echo "║   Free USB/IP Device Server for Pi       ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Get PC IP
if [ -n "$1" ]; then
    PC_IP="$1"
else
    echo ""
    read -p "Enter your Windows PC's IP address: " PC_IP
fi

if [ -z "$PC_IP" ]; then
    echo -e "${RED}Error: PC IP address is required${NC}"
    exit 1
fi

PC_PORT=3241
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "\n${GREEN}Installing with PC target: $PC_IP:$PC_PORT${NC}\n"

# [1/8] Install USB/IP packages
echo -e "${CYAN}[1/8] Installing USB/IP packages...${NC}"
apt-get update -qq
apt-get install -y -qq usbip hwdata > /dev/null 2>&1
modprobe usbip-host
echo "usbip-host" >> /etc/modules 2>/dev/null || true
echo -e "${GREEN}  ✓ Packages installed${NC}"

# [2/8] Configure USB/IP daemon service
echo -e "${CYAN}[2/8] Configuring USB/IP daemon service...${NC}"
cat > /etc/systemd/system/usbipd.service << EOF
[Unit]
Description=USB/IP Host Daemon
After=network.target

[Service]
Type=forking
ExecStart=/usr/sbin/usbipd -D
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable usbipd > /dev/null 2>&1
systemctl start usbipd 2>/dev/null || true
echo -e "${GREEN}  ✓ usbipd service installed and started${NC}"

# [3/8] Install auto-bind event script (hot-plug handler)
echo -e "${CYAN}[3/8] Installing auto-bind event script...${NC}"
if [ -f "$SCRIPT_DIR/usbip-event.sh.template" ]; then
    sed "s|__PC_IP__|$PC_IP|g" "$SCRIPT_DIR/usbip-event.sh.template" > /usr/local/bin/usbip-event.sh
else
    # Download from GitHub if running via curl | bash
    curl -sL "https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/usbip-event.sh.template" | \
        sed "s|__PC_IP__|$PC_IP|g" > /usr/local/bin/usbip-event.sh
fi
chmod +x /usr/local/bin/usbip-event.sh
echo -e "${GREEN}  ✓ Event script installed${NC}"

# [4/8] Install boot-time auto-bind script (bind only, no network)
echo -e "${CYAN}[4/8] Installing boot-time auto-bind script...${NC}"
if [ -f "$SCRIPT_DIR/usbip-startup.sh.template" ]; then
    cp "$SCRIPT_DIR/usbip-startup.sh.template" /usr/local/bin/usbip-startup.sh
else
    curl -sL "https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/usbip-startup.sh.template" \
        > /usr/local/bin/usbip-startup.sh
fi
chmod +x /usr/local/bin/usbip-startup.sh
echo -e "${GREEN}  ✓ Startup script installed${NC}"

# [5/8] Install udev rules
echo -e "${CYAN}[5/8] Installing udev rules...${NC}"
if [ -f "$SCRIPT_DIR/99-usbip-autobind.rules" ]; then
    cp "$SCRIPT_DIR/99-usbip-autobind.rules" /etc/udev/rules.d/
else
    curl -sL "https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/99-usbip-autobind.rules" \
        > /etc/udev/rules.d/99-usbip-autobind.rules
fi
udevadm control --reload-rules
echo -e "${GREEN}  ✓ udev rules installed${NC}"

# [6/8] Install auto-bind boot service
echo -e "${CYAN}[6/8] Installing auto-bind boot service...${NC}"
if [ -f "$SCRIPT_DIR/usbip-autobind.service" ]; then
    cp "$SCRIPT_DIR/usbip-autobind.service" /etc/systemd/system/
else
    curl -sL "https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/usbip-autobind.service" \
        > /etc/systemd/system/usbip-autobind.service
fi
systemctl daemon-reload
systemctl enable usbip-autobind > /dev/null 2>&1
echo -e "${GREEN}  ✓ Auto-bind boot service enabled${NC}"

# [7/8] Install network announce script
echo -e "${CYAN}[7/8] Installing network announce script...${NC}"
# Install the announce script
if [ -f "$SCRIPT_DIR/zerohub-announce.sh.template" ]; then
    sed "s|__PC_IP__|$PC_IP|g" "$SCRIPT_DIR/zerohub-announce.sh.template" > /usr/local/bin/zerohub-announce.sh
else
    curl -sL "https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/zerohub-announce.sh.template" | \
        sed "s|__PC_IP__|$PC_IP|g" > /usr/local/bin/zerohub-announce.sh
fi
chmod +x /usr/local/bin/zerohub-announce.sh

# Detect network manager and install appropriate hook
if command -v nmcli &> /dev/null && systemctl is-active NetworkManager &> /dev/null; then
    # Pi OS with NetworkManager — use dispatcher
    if [ -f "$SCRIPT_DIR/99-zerohub-announce" ]; then
        sed "s|__PC_IP__|$PC_IP|g" "$SCRIPT_DIR/99-zerohub-announce" > /etc/NetworkManager/dispatcher.d/99-zerohub-announce
    else
        curl -sL "https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/99-zerohub-announce" | \
            sed "s|__PC_IP__|$PC_IP|g" > /etc/NetworkManager/dispatcher.d/99-zerohub-announce
    fi
    chmod +x /etc/NetworkManager/dispatcher.d/99-zerohub-announce
    echo -e "${GREEN}  ✓ NetworkManager announce hook installed${NC}"
else
    # DietPi or other distros — use systemd service
    if [ -f "$SCRIPT_DIR/zerohub-announce.service" ]; then
        cp "$SCRIPT_DIR/zerohub-announce.service" /etc/systemd/system/
    else
        curl -sL "https://raw.githubusercontent.com/Penderrin-Projects/ZeroHub/main/pi/zerohub-announce.service" \
            > /etc/systemd/system/zerohub-announce.service
    fi
    systemctl daemon-reload
    systemctl enable zerohub-announce > /dev/null 2>&1
    echo -e "${GREEN}  ✓ Systemd announce service installed${NC}"
fi

# [8/8] Configure firewall
echo -e "${CYAN}[8/8] Configuring firewall...${NC}"
if command -v ufw &> /dev/null && ufw status | grep -q "active"; then
    ufw allow 3240/tcp > /dev/null 2>&1
    echo -e "${GREEN}  ✓ Firewall rule added (port 3240)${NC}"
elif command -v iptables &> /dev/null; then
    iptables -C INPUT -p tcp --dport 3240 -j ACCEPT 2>/dev/null || \
        iptables -A INPUT -p tcp --dport 3240 -j ACCEPT 2>/dev/null
    echo -e "${GREEN}  ✓ iptables rule added (port 3240)${NC}"
else
    echo -e "${GREEN}  ✓ No active firewall detected — no changes needed${NC}"
fi

# Done
PI_IP=$(hostname -I | awk '{print $1}')
echo -e "\n${CYAN}╔══════════════════════════════════════════╗"
echo "║          Installation Complete!           ║"
echo -e "╚══════════════════════════════════════════╝${NC}\n"
echo "  Pi IP:         ${GREEN}$PI_IP${NC}"
echo "  PC target:     ${GREEN}$PC_IP:$PC_PORT${NC}"
echo "  Log file:      /var/log/usbip-event.log"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Run the Windows installer on your PC"
echo "  2. Enter this Pi's IP ($PI_IP) when prompted"
echo "  3. Plug a USB device into the Pi — it will appear on your PC automatically"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  sudo systemctl status usbipd          # Check daemon status"
echo "  sudo usbip list -l                     # List bound devices"
echo "  cat /var/log/usbip-event.log           # View event log"
echo "  lsusb                                  # List connected USB devices"
echo ""
