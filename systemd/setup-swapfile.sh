#!/bin/bash

# Script to create and enable a 32GB swapfile for hibernation
# This is needed because zram cannot be used for hibernation

set -e  # Exit on error

SWAPSIZE="32"  # Size in GB

echo "Creating ${SWAPSIZE}GB swapfile for hibernation..."
echo "This will take a few minutes..."

# Check filesystem type
FSTYPE=$(df -T / | tail -1 | awk '{print $2}')
echo "Detected filesystem: $FSTYPE"
echo ""

# Set swapfile path based on filesystem
if [ "$FSTYPE" == "btrfs" ]; then
    SWAPFILE="/swap/swapfile"
else
    SWAPFILE="/swapfile"
fi

# Check if swapfile already exists
if [ -f "$SWAPFILE" ]; then
    echo "Error: $SWAPFILE already exists!"
    echo "Remove it first with: sudo rm $SWAPFILE"
    exit 1
fi

# Create swapfile (Btrfs requires special handling)
if [ "$FSTYPE" == "btrfs" ]; then
    echo "Creating Btrfs-compatible swapfile with dedicated subvolume..."

    # Create swap subvolume if it doesn't exist
    if [ ! -d "/swap" ]; then
        echo "Creating swap subvolume..."
        sudo btrfs subvolume create /swap
    fi

    # Use btrfs's built-in mkswapfile command (handles COW, compression, preallocation)
    echo "Creating swapfile with btrfs filesystem mkswapfile..."
    echo "This automatically disables COW, compression, and preallocates space."
    sudo btrfs filesystem mkswapfile --size ${SWAPSIZE}g --uuid clear $SWAPFILE
else
    echo "Creating swapfile..."
    # Standard method for ext4 and others
    sudo fallocate -l ${SWAPSIZE}G $SWAPFILE
    sudo chmod 600 $SWAPFILE

    # Format as swap (btrfs mkswapfile does this automatically)
    echo "Formatting as swap..."
    sudo mkswap $SWAPFILE
fi

echo ""

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
