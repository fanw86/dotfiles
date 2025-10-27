# dotfiles

This repository holds my dotfiles and helper scripts used to provision a personal environment.

## Using `i3wm.sh` to install i3wm

The `i3wm.sh` script in this repository is intended to help install and (optionally) configure the i3 window manager on a Linux system.

Important notes / assumptions:
- Review the script before running it. Do not run scripts you don't trust.
- The instructions below assume a Debian/Ubuntu-like distribution (apt-based). If you use another distro, adapt the package manager and package names accordingly.
- Back up existing configuration files (for example, `~/.config/i3`) before running an installer script.

Quick steps

1. Inspect the script:

```bash
# open in your pager or editor
less i3wm.sh
```

2. Make it executable (if it isn't already):

```bash
chmod +x ./i3wm.sh
```

3. Run the script. If the script installs system packages it will require elevated privileges. Run with `sudo` when needed:

```bash
# run as your user if it's only user-level changes
./i3wm.sh

# OR, if it installs packages or writes system files
sudo ./i3wm.sh
```

### Using the raw file (download from GitHub)

If you prefer to fetch the installer directly from the repository (for example, from the GitHub raw URL), you can download it with `curl` or `wget`. Replace the URL below with the raw URL for the branch/path you want — for this repo the raw path is:

```
https://raw.githubusercontent.com/fanw86/dotfiles/main/i3wm.sh
```

Recommended (safe) flow — download, inspect, then run:

```bash
# download to local file
curl -fsSL https://raw.githubusercontent.com/fanw86/dotfiles/main/i3wm.sh -o i3wm.sh
# inspect before running
less i3wm.sh
chmod +x ./i3wm.sh
./i3wm.sh            # or sudo ./i3wm.sh if it needs root
```

Quick (less safe) one-liners — not recommended because they run code without inspection:

```bash
# pipe to bash (runs immediately)
curl -fsSL https://raw.githubusercontent.com/fanw86/dotfiles/main/i3wm.sh | bash

# or with sudo (runs with root privileges)
curl -fsSL https://raw.githubusercontent.com/fanw86/dotfiles/main/i3wm.sh | sudo bash

# wget equivalent (download then run)
wget -qO- https://raw.githubusercontent.com/fanw86/dotfiles/main/i3wm.sh | bash
```

Safer alternative that avoids creating a file on disk while still allowing a quick inspect with `less`:

```bash
# open in pager without saving permanently
curl -fsSL https://raw.githubusercontent.com/fanw86/dotfiles/main/i3wm.sh | less

# run in a sub-shell (still executes without persistent file)
bash <(curl -fsSL https://raw.githubusercontent.com/fanw86/dotfiles/main/i3wm.sh)
```

If you plan to run scripts from the web regularly, consider verifying an accompanying checksum or GPG signature. Always review the script contents before running it, especially with sudo.

Post-install
- Log out and select the i3 session in your login manager, or start an i3 session with your display manager/startx as appropriate.
- Check `~/.config/i3` for generated or updated configuration files.

Troubleshooting & tips
- If the script installs packages, ensure you run `sudo apt update` first (or let the script do it).
- Common packages related to i3 setups: `i3`, `i3status`/`i3blocks`, `dmenu` or `rofi`, `feh` (for wallpaper), `picom`/`compton` (compositor), and an X server like `xorg`.
- If you prefer to test without installing: copy the configuration fragments from the script into your config directory manually.

Contributing
- If you improve `i3wm.sh`, please open a pull request with a short description of the change and testing steps.

If you want, I can also add a small verification step or a dry-run mode to `i3wm.sh`. Just tell me what behavior you prefer.

