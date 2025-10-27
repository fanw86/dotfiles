#!/usr/bin/env bash
# GitHub Copilot
# Minimal installer script to set up i3 window manager on an Arch Linux system.
# Usage: sudo ./i3wm.sh [username] [--lightdm]
# If username is not provided, script will prompt. Use --lightdm to install & enable LightDM.

set -euo pipefail
IFS=$'\n\t'

REQUIRED_OS="arch"
USERNAME=""
ENABLE_LIGHTDM=0

# parse args
for arg in "$@"; do
    case "$arg" in
        --lightdm) ENABLE_LIGHTDM=1 ;;
        *) USERNAME="$arg" ;;
    esac
done

# helpers
err() { printf '%s\n' "$*" >&2; exit 1; }
info() { printf '%s\n' "$*"; }

# must be root
if [ "$(id -u)" -ne 0 ]; then
    err "Please run as root (sudo)."
fi

# basic OS check
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if ! printf '%s\n' "${ID:-}" "${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]' | grep -q "$REQUIRED_OS"; then
        err "This script is intended for Arch Linux. /etc/os-release does not look like Arch."
    fi
else
    err "/etc/os-release not found. Are you on Linux?"
fi

# ask for username if not passed
if [ -z "$USERNAME" ]; then
    read -rp "Enter the non-root username to configure (~/.xinitrc will be written) : " USERNAME
fi
if ! id "$USERNAME" &>/dev/null; then
    read -rp "User '$USERNAME' does not exist. Create it? [y/N]: " create_user
    create_user=${create_user:-N}
    if [[ "$create_user" =~ ^[Yy]$ ]]; then
        read -rp "Create home directory? [Y/n]: " create_home
        create_home=${create_home:-Y}
        if [[ "$create_home" =~ ^[Yy]$ ]]; then
            useradd -m -G wheel "$USERNAME"
        else
            useradd -G wheel "$USERNAME"
        fi
        info "User '$USERNAME' created. Set password now."
        passwd "$USERNAME"
    else
        err "User not found. Exiting."
    fi
fi

# Minimal package list for a functional i3 setup
PACKAGES=(
    xorg-server
    xorg-xinit
    xorg-apps
    mesa
    xf86-video-vesa
    i3-wm
    i3status
    dmenu
    xterm
    xorg-xsetroot
    xorg-xrandr
    xorg-xset
    networkmanager
    polkit
    xorg-twm  # tiny fallback window manager/tools
)

# optional extras
EXTRA_PACKAGES=(
    i3lock
    rofi
    picom
    firefox
    xorg-fonts-misc
    gvfs
)

PACKAGES+=( "${EXTRA_PACKAGES[@]}" )

if [ "$ENABLE_LIGHTDM" -eq 1 ]; then
    PACKAGES+=( lightdm lightdm-gtk-greeter )
fi

info "Updating system and installing packages. This may take a while..."
pacman -Syu --noconfirm --needed "${PACKAGES[@]}"

info "Enabling NetworkManager service..."
systemctl enable --now NetworkManager

if [ "$ENABLE_LIGHTDM" -eq 1 ]; then
    info "Enabling LightDM display manager..."
    systemctl enable --now lightdm
fi

# set up .xinitrc for the user
USER_HOME=$(eval echo "~$USERNAME")
XINIT="$USER_HOME/.xinitrc"

info "Writing $XINIT to start i3 (will be overwritten if exists)."
cat > "$XINIT" <<'XINIT_EOF'
#!/bin/sh
# ~/.xinitrc for i3
# Start necessary background services/programs here if desired:
# e.g. /usr/bin/nm-applet &
# e.g. /usr/bin/picom &

# set keyboard repeat and layout if needed:
# setxkbmap -layout us

# Start i3
exec i3
XINIT_EOF

chown "$USERNAME":"$USERNAME" "$XINIT"
chmod 644 "$XINIT"

info "Installation complete."

cat <<EOF

Next steps for user '$USERNAME':
- If you installed a display manager (LightDM), simply reboot or login via the greeter.
- Otherwise, login as $USERNAME and run:
        startx

- Customize ~/.xinitrc to start background apps (nm-applet, picom, etc.)
- i3 config lives at: ~/.config/i3/config (run i3 once to auto-generate or copy from /etc/i3)

Useful docs:
- Arch Wiki i3: https://wiki.archlinux.org/title/I3
- Arch Wiki Xorg: https://wiki.archlinux.org/title/Xorg

EOF