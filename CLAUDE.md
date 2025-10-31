# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository managed with GNU Stow. Dotfiles are organized into separate packages (directories), each containing configuration files in a directory structure that mirrors the home directory. Stow creates symlinks from the home directory to files in this repository.

## GNU Stow Management

Stow manages all configurations through symlinks. Each top-level directory is a "package" that can be independently installed:

```bash
# Install a package (creates symlinks from ~ to this repo)
stow <package-name>

# Install with --adopt flag if config already exists (CAREFUL: overwrites repo files)
stow <package-name> --adopt

# After adopt, restore repo version
git restore <package-name>

# Uninstall a package (removes symlinks)
stow -D <package-name>
```

**Directory Structure Pattern:** Each package directory contains the same path structure as if this repo was `~`. For example:
- `nvim/.config/nvim/` symlinks to `~/.config/nvim/`
- `doom/.config/doom/` symlinks to `~/.config/doom/`
- `zsh/.zshrc` symlinks to `~/.zshrc`

## Configuration Packages

### Neovim (nvim/)
- **Location:** `nvim/.config/nvim/`
- **Package Manager:** Packer
- **Setup:**
  1. Install nightly version of neovim (some plugins require latest features, especially treesitter)
  2. Install Packer: https://github.com/wbthomason/packer.nvim
  3. Run `:PackerSync` or `:PackerInstall` in nvim
  4. May need `:TSUpdate` for treesitter
- **Structure:**
  - `init.lua` - Entry point, loads catppuccin/carbonfox theme with transparent background
  - `lua/me/` - Modular configuration:
    - `options.lua` - Vim options
    - `globals.lua` - Global variables
    - `keymap.lua` - Key mappings
    - `lsp.lua` - LSP configuration
    - `telescope.lua` - Telescope fuzzy finder config
    - `lualine.lua` - Status line config
- **Theme:** carbonfox with transparent background

### Doom Emacs (doom/)
- **Location:** `doom/.config/doom/`
- **Setup:**
  1. Install emacs (see NixOS config for dependencies)
  2. Install Doom Emacs
  3. Run `doom sync` after installing this config
  4. May need `<M-x> package-install` for missing packages
- **Files:**
  - `init.el` - Doom modules configuration (what features are enabled)
  - `config.el` - Custom configuration
  - `packages.el` - Package declarations
  - `custom.el` - Custom settings
- **Key Dependencies (for NixOS):**
  - System clipboard: `xclip` (Linux/X11) or `pbcopy` (Mac)
  - Emacs packages: pbcopy, vterm, libvterm, libtool, gcc
  - Language servers: gopls, haskell-language-server
- **Enabled Languages:** C/C++, Elm, Emacs Lisp, Go, Haskell, Lua, Markdown, Org, Shell, Zig
- **Key Features:** LSP, tree-sitter, magit (git), vterm (terminal), evil mode (vim bindings)

### Window Managers

#### i3 (i3/)
- **Location:** `i3/.config/i3/config`
- X11 tiling window manager configuration

#### Sway (sway/ and swayfx/)
- **Location:** `sway/.config/sway/config` and `swayfx/.config/sway/config`
- Wayland compositor (i3-compatible)
- Includes `sway_bar.sh` script for status bar

#### Waybar (waybar/)
- **Location:** `waybar/.config/waybar/`
- Status bar for Wayland compositors

#### Polybar (polybar/)
- **Location:** `polybar/.config/polybar/`
- Status bar for X11 window managers
- Includes `launch.sh`, `power.sh`, and weather script

### Tmux (tmux/)
- **Location:** `tmux/.tmux.conf`
- **Plugin Manager:** TPM (tmux-plugins/tpm)
- **Setup:**
  1. Install TPM: https://github.com/tmux-plugins/tpm
  2. Reload config: `tmux source ~/.tmux.conf`
  3. Install plugins: `prefix + I` (capital I)
- **Plugins:**
  - tmux-sensible
  - dracula/tmux (theme with battery, weather, time)
- **Features:** Mouse support, 256-color support

### Zsh (zsh/)
- **Location:** `zsh/.zshrc`
- Shell configuration

### Banner (banner/)
- Custom banner/welcome message

## NixOS Configuration

**File:** `configuration.nix` (root level, not managed by stow)

**Update NixOS:**
```bash
# Apply configuration changes and update packages
sudo nixos-rebuild switch

# Search for packages
nix search <package-name>
```

**Package Search:** https://search.nixos.org

**Key Configuration:**
- User: bashbunni with Fish shell
- Desktop: GNOME with GDM (with autologin)
- Display: X11 with mac keyboard variant
- Audio: PipeWire
- Fonts: Terminess Nerd Font, Blex Mono, IBM Plex, OpenMoji Color
- Yubikey: Configured for sudo authentication via pam_u2f
- Features: Flakes and nix-command enabled

**Important Notes:**
- Config is manually copied to this repo (not symlinked)
- Emacs overlay from nix-community for Emacs 28+
- Broadcom wifi driver uses insecure package (permitted)

## SSH with Yubikey

Generate 2FA SSH key stored on Yubikey:
```bash
ssh-keygen -t ed25519-sk -O resident
```

## Important Development Context

- This is a personal configuration repository for Linux systems (primarily NixOS)
- Window manager preference: Sway/SwayFX (Wayland) and i3 (X11)
- Editor preference: Neovim (primary) and Doom Emacs (secondary)
- Terminal multiplexer: Tmux with Dracula theme
- Color schemes: Catppuccin latte, carbonfox (transparent backgrounds)
- All configurations favor keyboard-driven workflows with vim-style bindings
