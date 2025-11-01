#!/bin/bash

# Script to apply systemd logind and sleep configurations
# This configures lid close behavior and hibernation settings

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGIND_CONF="$SCRIPT_DIR/logind.conf"
SLEEP_CONF="$SCRIPT_DIR/sleep.conf"

echo "Applying systemd configurations from dotfiles..."
echo ""

# Check if config files exist
if [ ! -f "$LOGIND_CONF" ]; then
    echo "Error: $LOGIND_CONF not found!"
    exit 1
fi

if [ ! -f "$SLEEP_CONF" ]; then
    echo "Error: $SLEEP_CONF not found!"
    exit 1
fi

# Backup existing configs
echo "Backing up existing configurations..."
if [ -f /etc/systemd/logind.conf ]; then
    sudo cp /etc/systemd/logind.conf /etc/systemd/logind.conf.backup
    echo "  Backed up: /etc/systemd/logind.conf.backup"
fi

if [ -f /etc/systemd/sleep.conf ]; then
    sudo cp /etc/systemd/sleep.conf /etc/systemd/sleep.conf.backup
    echo "  Backed up: /etc/systemd/sleep.conf.backup"
fi

# Copy new configs
echo ""
echo "Installing new configurations..."
sudo cp "$LOGIND_CONF" /etc/systemd/logind.conf
echo "  Installed: /etc/systemd/logind.conf"

sudo cp "$SLEEP_CONF" /etc/systemd/sleep.conf
echo "  Installed: /etc/systemd/sleep.conf"

# Restart systemd-logind
echo ""
echo "Restarting systemd-logind service..."
#sudo systemctl restart systemd-logind

echo ""
echo "✓ Systemd configurations applied successfully!"
echo ""
echo "Configuration summary:"
echo "  - Close lid: Lock screen + suspend"
echo "  - Lid closed for 30 min: Hibernate"
echo "  - Lid open + idle: No action"
echo "  - Docked with lid closed: Ignore"
echo ""
echo "Note: Make sure you have sufficient swap space for hibernation."
echo "Run ../setup-swapfile.sh if you haven't already."
