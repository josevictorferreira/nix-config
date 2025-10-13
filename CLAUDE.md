# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a cross-platform Nix configuration repository managing both NixOS desktop and macOS MacBook environments. The configuration uses a modular structure with shared home-manager configurations and platform-specific customizations.

## Common Commands

### System Management
- `make rebuild` - Rebuild and switch to the configuration (detects platform automatically)
- `make boot` - Rebuild NixOS boot configuration (NixOS only)
- `make check` - Validate flake configuration without building
- `make update` - Update flake inputs
- `make clean` - Clean up Nix store garbage collection

### Secrets Management
- `make secrets` - Edit encrypted secrets file
- `make up_keys` - Update encryption keys for secrets
- Secrets are stored in `secrets/secrets.enc.yaml` using SOPS with age encryption

### Git Subtree Management
- `make subtree_sync` - Sync all external configuration subtrees
- External configurations are managed as git subtrees defined in Makefile SUBTRESS variable

### Platform-Specific
**NixOS Desktop:**
- `sudo nixos-rebuild switch --flake .#nixos-desktop`
- `sudo nixos-rebuild boot --flake .#nixos-desktop`

**macOS MacBook:**
- `darwin-rebuild switch --flake .#macos-macbook`
- First-time setup: `nix build .#darwinConfigurations.josevictorferreira-macos.system`

## Project Architecture

### Core Structure
```
flake.nix                    # Main flake with system configurations
hosts/                       # Platform-specific system configurations
├── nixos-desktop/          # NixOS desktop configuration
└── macos-macbook/          # macOS MacBook configuration
home-manager/               # User environment configurations
├── shared/                 # Cross-platform user configurations
└── {host}/                 # Host-specific home-manager configs
modules/                    # Reusable NixOS modules
├── hardware/               # Hardware-specific configurations
└── security/               # Security-related modules
dotfiles/                   # Traditional dotfile configurations
secrets/                    # Encrypted configuration secrets
```

### Key Categories

#### Shared Home Manager (`home-manager/shared/`)
- `development/` - Development tools and languages
  - `languages.nix` - Node.js, Rust, Lua
  - `formatters.nix` - Prettier, stylua, nixfmt
  - `lsp-servers.nix` - Language server configurations
  - `claude.nix` - Claude Code editor configuration
- Application configs: `neovim.nix`, `kitty.nix`, `tmux.nix`, etc.
- Shell: `zsh.nix` with custom aliases and settings

#### Hyprland Desktop (`home-manager/shared/hyprland/`)
- Wayland window manager configuration
- Waybar configurations with multiple styles
- AGS desktop widgets and overview
- Rofi application launcher themes
- Swaync notification center
- Wallust color scheme generation

#### Development Environment
- Primary editor: Neovim with custom Lua configuration
- Terminal: Kitty (and Alacritty as fallback)
- Multiplexer: Tmux with session management
- LSP support for multiple languages
- Git integration with custom settings
- Claude Code as default AI coding assistant

#### Platform Differences
- **NixOS**: Full system configuration, hardware drivers, gaming support
- **macOS**: Home-manager only system configuration, native macOS optimizations

### Modularity Features

#### Host Variables
Each host has `variables.nix` containing host-specific settings:
- `gitUsername` - Git configuration name
- `keyboardLayout` - System keyboard layout

#### Hardware Modules
`modules/hardware/` contains:
- Graphics drivers (NVIDIA, AMD, Intel)
- Printer drivers (HP-1020)
- Network storage configurations (CephFS, SMB)
- Virtualization support

#### Security Modules
`modules/security/` contains:
- SOPS encryption for secrets
- Polkit authorization rules

## Configuration Management

### Flake Structure
The flake defines two systems:
- `nixos-desktop` (x86_64-linux)
- `macos-macbook` (aarch64-darwin)

Both systems share home-manager configurations through the `shared/` directory, with platform-specific overrides in host-specific directories.

### Secrets Configuration
Secrets are managed with SOPS and age encryption:
- SSH keys are converted to age keys for encryption
- Multiple recipients can be configured for team access
- Age keys stored in `~/.config/sops/age/keys.txt`

### External Dependencies
The configuration uses git subtrees for external dotfiles:
- nvim, tmux, zsh, ghostty, kitty, waybar configurations
- Hyprland desktop setup
- Application-specific configurations

## Development Workflow

### Adding New Configuration
1. Add shared configuration to `home-manager/shared/`
2. Add platform-specific overrides to `home-manager/{host}/`
3. Import new modules in appropriate `default.nix`
4. Test with `make check` before applying

### Managing External Subtrees
1. Update subtree URLs in Makefile SUBTRESS variable
2. Run `make subtree_sync` to pull/push changes
3. Commit subtree updates to main repository

### Secrets Management
1. Edit secrets with `make secrets`
2. Update keys when team membership changes with `make up_keys`
3. Never commit unencrypted secrets

## Testing and Validation

Always run validation commands before applying:
- `make check` - Validate flake syntax and dependencies
- `nix flake check --show-trace` - Detailed validation
- Test on non-production system first when possible

## Known Issues and Fixes

- **Darwin GID mismatch**: `sudo dscl . -change /Groups/nixbld PrimaryGroupID 350 30000`
- **Spotify cache issues**: `rm -rf ~/.cache/spotify`
- **Hyprland screenshot**: Use proper permissions for screenshot utilities