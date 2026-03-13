#!/bin/bash
# ZeroHub - Pi Uninstaller
echo "Uninstalling ZeroHub..."

# Stop services
systemctl stop usbipd 2>/dev/null
systemctl stop usbip-autobind 2>/dev/null
systemctl stop zerohub-announce 2>/dev/null
systemctl disable usbipd 2>/dev/null
systemctl disable usbip-autobind 2>/dev/null
systemctl disable zerohub-announce 2>/dev/null

# Remove service files
rm -f /etc/systemd/system/usbipd.service
rm -f /etc/systemd/system/usbip-autobind.service
rm -f /etc/systemd/system/zerohub-announce.service

# Remove scripts
rm -f /usr/local/bin/usbip-event.sh
rm -f /usr/local/bin/usbip-startup.sh
rm -f /usr/local/bin/zerohub-announce.sh

# Remove udev rules
rm -f /etc/udev/rules.d/99-usbip-autobind.rules
udevadm control --reload-rules 2>/dev/null

# Remove NetworkManager dispatcher
rm -f /etc/NetworkManager/dispatcher.d/99-zerohub-announce

# Remove log
rm -f /var/log/usbip-event.log

# Reload systemd
systemctl daemon-reload

echo ""
echo "ZeroHub has been uninstalled."
echo "Note: usbip packages were NOT removed. To remove them:"
echo "  sudo apt remove usbip hwdata"
echo ""
