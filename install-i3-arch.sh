#!/bin/bash
# i3wm Setup Script for Arch Linux
# This script installs all necessary packages for the i3wm configuration in this dotfiles repo

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== i3wm Installation Script ===${NC}"
echo "This script will install all packages needed for the i3wm configuration"
echo ""

# Check if running on Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}Error: This script is designed for Arch Linux${NC}"
    exit 1
fi

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root${NC}"
    exit 1
fi

echo -e "${YELLOW}Updating package database...${NC}"
sudo pacman -Sy

# Core i3 packages
echo -e "${GREEN}Installing core i3 packages...${NC}"
sudo pacman -S --needed --noconfirm \
    i3-wm \
    i3status \
    i3lock

# Essential dependencies
echo -e "${GREEN}Installing essential dependencies...${NC}"
sudo pacman -S --needed --noconfirm \
    polybar \
    rofi \
    flameshot \
    xss-lock \
    networkmanager \
    nm-applet \
    xorg-xrandr \
    xorg-server \
    xorg-xinit

# Audio (PipeWire)
echo -e "${GREEN}Installing PipeWire audio system...${NC}"
sudo pacman -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    pavucontrol

# Fonts
echo -e "${GREEN}Installing fonts...${NC}"
sudo pacman -S --needed --noconfirm \
    ttf-font-awesome \
    ttf-dejavu \
    ttf-liberation

# Check for AUR helper
if command -v yay &> /dev/null; then
    echo -e "${GREEN}Installing additional fonts from AUR...${NC}"
    yay -S --needed --noconfirm ttf-iosevka-nerd || true
elif command -v paru &> /dev/null; then
    echo -e "${GREEN}Installing additional fonts from AUR...${NC}"
    paru -S --needed --noconfirm ttf-iosevka-nerd || true
else
    echo -e "${YELLOW}No AUR helper found. Skipping ttf-iosevka-nerd (optional)${NC}"
    echo "You can install yay or paru later and run: yay -S ttf-iosevka-nerd"
fi

# i3lock-fancy (might need AUR)
if command -v yay &> /dev/null; then
    echo -e "${GREEN}Installing i3lock-fancy from AUR...${NC}"
    yay -S --needed --noconfirm i3lock-fancy-git || {
        echo -e "${YELLOW}Failed to install i3lock-fancy, trying regular i3lock${NC}"
        sudo pacman -S --needed --noconfirm i3lock
    }
elif command -v paru &> /dev/null; then
    echo -e "${GREEN}Installing i3lock-fancy from AUR...${NC}"
    paru -S --needed --noconfirm i3lock-fancy-git || {
        echo -e "${YELLOW}Failed to install i3lock-fancy, trying regular i3lock${NC}"
        sudo pacman -S --needed --noconfirm i3lock
    }
else
    echo -e "${YELLOW}i3lock-fancy requires AUR helper. Using regular i3lock instead${NC}"
    sudo pacman -S --needed --noconfirm i3lock
fi

# Terminal emulator
echo -e "${GREEN}Installing terminal emulator...${NC}"
read -p "Choose terminal emulator (1=alacritty, 2=kitty, 3=skip): " term_choice
case $term_choice in
    1)
        sudo pacman -S --needed --noconfirm alacritty
        ;;
    2)
        sudo pacman -S --needed --noconfirm kitty
        ;;
    *)
        echo -e "${YELLOW}Skipping terminal installation${NC}"
        ;;
esac

# Optional packages
echo ""
echo -e "${GREEN}Optional packages:${NC}"
read -p "Install compositor (picom) for transparency/shadows? [Y/n]: " install_picom
if [[ $install_picom != "n" && $install_picom != "N" ]]; then
    sudo pacman -S --needed --noconfirm picom
fi

read -p "Install wallpaper setter (feh)? [Y/n]: " install_feh
if [[ $install_feh != "n" && $install_feh != "N" ]]; then
    sudo pacman -S --needed --noconfirm feh
fi

read -p "Install file manager (thunar)? [Y/n]: " install_fm
if [[ $install_fm != "n" && $install_fm != "N" ]]; then
    sudo pacman -S --needed --noconfirm thunar
fi

# Doom Emacs dependencies (from config)
read -p "Install Doom Emacs dependencies? [Y/n]: " install_doom
if [[ $install_doom != "n" && $install_doom != "N" ]]; then
    echo -e "${GREEN}Installing Doom Emacs dependencies...${NC}"
    sudo pacman -S --needed --noconfirm \
        emacs \
        git \
        ripgrep \
        fd
fi

# Enable services
echo ""
echo -e "${GREEN}Enabling system services...${NC}"
sudo systemctl enable --now NetworkManager

# PipeWire is socket-activated by default, no need to enable manually
echo -e "${GREEN}PipeWire will start automatically${NC}"

# Post-installation instructions
echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Install dotfiles: cd ~/dotfiles && stow i3 polybar"
echo "2. Update network interface in polybar config:"
echo "   - Run 'ip link' to find your wireless interface name"
echo "   - Edit polybar/.config/polybar/config line 181"
echo "   - Change 'wlp3s0' to your interface name"
echo "3. Reboot or start X with 'startx' (make sure to configure .xinitrc first)"
echo "4. Optional: Install Doom Emacs: git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs"
echo "   Then run: ~/.config/emacs/bin/doom install"
echo ""
echo -e "${GREEN}Enjoy your i3wm setup!${NC}"
