#!/bin/bash

# Script to create and enable a 32GB swapfile for hibernation
# This is needed because zram cannot be used for hibernation

set -e  # Exit on error

SWAPFILE="/swapfile"
SWAPSIZE="32"  # Size in GB

echo "Creating ${SWAPSIZE}GB swapfile for hibernation..."
echo "This will take a few minutes..."

# Check if swapfile already exists
if [ -f "$SWAPFILE" ]; then
    echo "Error: $SWAPFILE already exists!"
    echo "Remove it first with: sudo rm $SWAPFILE"
    exit 1
fi

# Check filesystem type
FSTYPE=$(df -T / | tail -1 | awk '{print $2}')
echo "Detected filesystem: $FSTYPE"
echo ""

# Create swapfile (Btrfs requires special handling)
if [ "$FSTYPE" == "btrfs" ]; then
    echo "Creating Btrfs-compatible swapfile..."
    # Create empty file with touch (must be completely empty for chattr +C)
    sudo touch $SWAPFILE
    # Disable COW (copy-on-write) - REQUIRED for Btrfs swapfiles
    echo "Disabling copy-on-write..."
    sudo chattr +C $SWAPFILE
    # Set permissions
    sudo chmod 600 $SWAPFILE
    # Fill the file
    echo "Filling swapfile (this takes time)..."
    sudo dd if=/dev/zero of=$SWAPFILE bs=1G count=$SWAPSIZE status=progress
else
    echo "Creating swapfile..."
    # Standard method for ext4 and others
    sudo fallocate -l ${SWAPSIZE}G $SWAPFILE
    sudo chmod 600 $SWAPFILE
fi

echo ""

# Make it a swap file
echo "Formatting as swap..."
sudo mkswap $SWAPFILE

# Enable the swapfile
echo "Enabling swapfile..."
sudo swapon $SWAPFILE

# Add to /etc/fstab for persistence
if grep -q "$SWAPFILE" /etc/fstab; then
    echo "Swapfile already in /etc/fstab"
else
    echo "Adding swapfile to /etc/fstab..."
    echo "$SWAPFILE none swap defaults 0 0" | sudo tee -a /etc/fstab
fi

# Show current swap status
echo ""
echo "✓ Swap setup complete!"
echo ""
echo "Current swap status:"
swapon --show

echo ""
echo "You now have:"
echo "  - zram: 4GB (compressed RAM swap)"
echo "  - swapfile: ${SWAPSIZE}GB (disk-based swap for hibernation)"
