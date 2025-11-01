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

# Create swapfile
echo "Creating swapfile..."
sudo dd if=/dev/zero of=$SWAPFILE bs=1G count=$SWAPSIZE status=progress

# Set correct permissions
echo "Setting permissions..."
sudo chmod 600 $SWAPFILE

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
echo "Swap setup complete!"
echo "Current swap status:"
swapon --show

echo ""
echo "You now have:"
echo "  - zram: 4GB (compressed RAM swap)"
echo "  - swapfile: ${SWAPSIZE}GB (disk-based swap for hibernation)"
