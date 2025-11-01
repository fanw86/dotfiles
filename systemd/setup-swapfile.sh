#!/bin/bash

# Script to create and enable a 34GB LVM swap volume for hibernation
# This is needed because zram cannot be used for hibernation
# LVM swap is more reliable than Btrfs swapfiles

set -e  # Exit on error

SWAPSIZE="34"  # Size in GB (32GB + ~6% overhead for hibernation)

echo "Creating ${SWAPSIZE}GB LVM swap volume for hibernation..."
echo ""

# Check if LVM is available
if ! command -v lvcreate &> /dev/null; then
    echo "Error: LVM tools not found. Install with: sudo pacman -S lvm2"
    exit 1
fi

# List available volume groups
echo "Detecting LVM volume groups..."
VG_LIST=$(sudo vgs --noheadings -o vg_name 2>/dev/null | tr -d ' ')

if [ -z "$VG_LIST" ]; then
    echo "Error: No LVM volume groups found!"
    echo "This script requires LVM. If you don't have LVM, you'll need a different approach."
    exit 1
fi

echo "Found volume group(s): $VG_LIST"
echo ""

# Get the first volume group (or prompt if multiple)
VG_COUNT=$(echo "$VG_LIST" | wc -l)
if [ $VG_COUNT -eq 1 ]; then
    VG_NAME="$VG_LIST"
    echo "Using volume group: $VG_NAME"
else
    echo "Multiple volume groups found:"
    echo "$VG_LIST"
    echo ""
    read -p "Enter the volume group name to use: " VG_NAME
fi

# Check if volume group exists
if ! sudo vgs "$VG_NAME" &>/dev/null; then
    echo "Error: Volume group '$VG_NAME' not found!"
    exit 1
fi

# Check free space
VG_FREE=$(sudo vgs --noheadings --units g -o vg_free "$VG_NAME" | tr -d ' ' | sed 's/g//')
VG_FREE_INT=${VG_FREE%.*}

echo ""
echo "Volume group: $VG_NAME"
echo "Free space: ${VG_FREE}G"
echo "Required: ${SWAPSIZE}G"
echo ""

if [ "$VG_FREE_INT" -lt "$SWAPSIZE" ]; then
    echo "Error: Not enough free space in volume group!"
    echo "Free: ${VG_FREE}G, Required: ${SWAPSIZE}G"
    exit 1
fi

# Check if swap LV already exists
if sudo lvs "$VG_NAME/swap" &>/dev/null; then
    echo "Error: Logical volume '$VG_NAME/swap' already exists!"
    echo "Remove it first with: sudo lvremove $VG_NAME/swap"
    exit 1
fi

# Create swap logical volume
echo "Creating swap logical volume..."
sudo lvcreate -L ${SWAPSIZE}G "$VG_NAME" -n swap

# Format as swap
echo "Formatting as swap..."
sudo mkswap /dev/$VG_NAME/swap

# Enable swap
echo "Enabling swap..."
sudo swapon /dev/$VG_NAME/swap

# Add to /etc/fstab for persistence
FSTAB_ENTRY="/dev/$VG_NAME/swap none swap defaults 0 0"
if grep -q "/dev/$VG_NAME/swap" /etc/fstab; then
    echo "Swap already in /etc/fstab"
else
    echo "Adding swap to /etc/fstab..."
    echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab
fi

# Show current swap status
echo ""
echo "✓ LVM Swap setup complete!"
echo ""
echo "Current swap status:"
swapon --show

echo ""
echo "You now have:"
echo "  - zram: 4GB (compressed RAM swap)"
echo "  - LVM swap: ${SWAPSIZE}GB (disk-based swap for hibernation)"
