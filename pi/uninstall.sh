#!/bin/bash
# ZeroHub - Pi Uninstaller
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root: sudo bash uninstall.sh${NC}"
    exit 1
fi

echo -e "${CYAN}Uninstalling ZeroHub...${NC}"

echo "Stopping and disabling services..."
systemctl stop usbip-autobind.service 2>/dev/null || true
systemctl disable usbip-autobind.service 2>/dev/null || true
systemctl stop usbipd.service 2>/dev/null || true
systemctl disable usbipd.service 2>/dev/null || true

echo "Removing files..."
rm -f /etc/systemd/system/usbip-autobind.service
rm -f /etc/systemd/system/usbipd.service
rm -f /usr/local/bin/usbip-event.sh
rm -f /usr/local/bin/usbip-startup.sh
rm -f /etc/udev/rules.d/99-usbip-autobind.rules
rm -f /var/log/usbip-event.log

systemctl daemon-reload
udevadm control --reload-rules

echo -e "${GREEN}ZeroHub uninstalled successfully.${NC}"
echo "Note: The 'usbip' package was not removed. Run 'sudo apt remove usbip' to remove it."
