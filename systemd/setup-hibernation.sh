#!/bin/bash

# Script to configure hibernation for systemd-boot with LVM swap
# Adds resume parameter to boot entries and configures initramfs

set -e  # Exit on error

echo "Configuring hibernation for systemd-boot..."
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires root privileges. Please run with sudo."
    exit 1
fi

# Find swap device
echo "Detecting swap device..."
SWAP_DEVICE=$(swapon --show --noheadings | grep -v zram | awk '{print $1}' | head -1)

if [ -z "$SWAP_DEVICE" ]; then
    echo "Error: No swap device found (excluding zram)!"
    echo "Please run setup-swapfile.sh first to create LVM swap."
    exit 1
fi

echo "Found swap device: $SWAP_DEVICE"
echo ""

# 1. Configure systemd-boot entry
BOOT_ENTRIES_DIR="/boot/loader/entries"

if [ ! -d "$BOOT_ENTRIES_DIR" ]; then
    echo "Error: $BOOT_ENTRIES_DIR not found!"
    echo "Are you sure you're using systemd-boot?"
    exit 1
fi

echo "Found boot entries:"
ENTRY_FILES=$(ls $BOOT_ENTRIES_DIR/*.conf 2>/dev/null)

if [ -z "$ENTRY_FILES" ]; then
    echo "Error: No boot entries found in $BOOT_ENTRIES_DIR"
    exit 1
fi

# Display entries with numbers
i=1
declare -A ENTRY_MAP
for ENTRY_FILE in $ENTRY_FILES; do
    ENTRY_NAME=$(basename "$ENTRY_FILE")
    ENTRY_TITLE=$(grep "^title" "$ENTRY_FILE" | cut -d' ' -f2- || echo "Unknown")
    HAS_RESUME=$(grep -q "resume=" "$ENTRY_FILE" && echo " [resume configured]" || echo "")

    echo "  [$i] $ENTRY_TITLE ($ENTRY_NAME)$HAS_RESUME"
    ENTRY_MAP[$i]="$ENTRY_FILE"
    ((i++))
done

echo ""
echo "Select which boot entry to configure for hibernation:"
echo "  Enter number(s) separated by space (e.g., '1 2' or 'all' for all entries)"
read -p "Selection: " SELECTION

# Parse selection
if [ "$SELECTION" == "all" ]; then
    SELECTED_ENTRIES=("${ENTRY_MAP[@]}")
else
    SELECTED_ENTRIES=()
    for NUM in $SELECTION; do
        if [ -n "${ENTRY_MAP[$NUM]}" ]; then
            SELECTED_ENTRIES+=("${ENTRY_MAP[$NUM]}")
        else
            echo "Warning: Invalid selection '$NUM', skipping."
        fi
    done
fi

if [ ${#SELECTED_ENTRIES[@]} -eq 0 ]; then
    echo "No valid entries selected. Exiting."
    exit 1
fi

echo ""
echo "Configuring selected boot entries..."
for ENTRY_FILE in "${SELECTED_ENTRIES[@]}"; do
    echo "Processing: $ENTRY_FILE"

    # Check if resume is already configured
    if grep -q "resume=" "$ENTRY_FILE"; then
        echo "  Resume parameter already present, skipping."
        continue
    fi

    # Backup the entry file
    cp "$ENTRY_FILE" "${ENTRY_FILE}.backup"
    echo "  Backed up to: ${ENTRY_FILE}.backup"

    # Add resume parameter to options line (use | as delimiter to avoid issues with / in device path)
    sed -i "/^options/s|$| resume=${SWAP_DEVICE}|" "$ENTRY_FILE"
    echo "  Added: resume=${SWAP_DEVICE}"
done

echo ""

# 2. Configure mkinitcpio.conf
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
echo "Configuring initramfs hooks..."

if [ ! -f "$MKINITCPIO_CONF" ]; then
    echo "Error: $MKINITCPIO_CONF not found!"
    exit 1
fi

# Check if resume hook is already present
if grep -q "^HOOKS=.*resume" "$MKINITCPIO_CONF"; then
    echo "Resume hook already present in mkinitcpio.conf"
else
    # Backup mkinitcpio.conf
    cp "$MKINITCPIO_CONF" "${MKINITCPIO_CONF}.backup"
    echo "Backed up: ${MKINITCPIO_CONF}.backup"

    # Add resume hook after udev (or filesystems if udev not found)
    if grep -q "^HOOKS=.*udev" "$MKINITCPIO_CONF"; then
        # Insert resume after filesystems but before fsck
        sed -i 's/\(^HOOKS=([^)]*filesystems[^)]*\)fsck/\1resume fsck/' "$MKINITCPIO_CONF"
        echo "Added resume hook after filesystems"
    else
        echo "Warning: Could not find standard HOOKS line in mkinitcpio.conf"
        echo "Please manually add 'resume' hook after 'filesystems' in HOOKS array"
        echo "Example: HOOKS=(base udev autodetect modconf block filesystems keyboard resume fsck)"
    fi
fi

echo ""

# 3. Regenerate initramfs
echo "Regenerating initramfs..."
mkinitcpio -P

echo ""
echo "✓ Hibernation configuration complete!"
echo ""
echo "Summary:"
echo "  - Swap device: $SWAP_DEVICE"
echo "  - Boot entries updated with resume parameter"
echo "  - Initramfs configured with resume hook"
echo ""
echo "Next steps:"
echo "  1. Reboot your system: sudo reboot"
echo "  2. After reboot, test hibernation: sudo systemctl hibernate"
echo "  3. Power on - your session should be restored"
echo ""
echo "Backups created:"
echo "  - Boot entries: ${BOOT_ENTRIES_DIR}/*.conf.backup"
echo "  - mkinitcpio: ${MKINITCPIO_CONF}.backup"
