# Home Manager to Pure Nix Refactoring Plan

## Overview
This document outlines the comprehensive plan for removing Home Manager from the repository and transitioning to pure Nix configurations. The current setup uses Home Manager for user environment management, which needs to be replaced with native NixOS and Nix-Darwin configurations.

## Current Architecture Analysis

### Home Manager Structure
- **`home-manager/shared/`** - Cross-platform user configurations
- **`home-manager/{host}/`** - Host-specific overrides
- **`dotfiles/`** - Configuration files managed by Home Manager

### Key Dependencies Found
1. **Flake inputs**: Home Manager is declared as a flake input
2. **Module imports**: Home Manager modules are imported in system configurations
3. **File management**: Home Manager handles dotfile deployment
4. **Package management**: User packages are managed through Home Manager

## Refactoring Tasks

### Phase 1: Infrastructure & Configuration Files

#### 1.1 Flake Configuration Updates
- [ ] Remove `home-manager` flake input from `flake.nix`
- [ ] Update flake outputs to remove Home Manager integration
- [ ] Remove `home-manager` from `flake.lock`

#### 1.2 Directory Structure Analysis
- [ ] Analyze `home-manager/shared/` for all user configurations
- [ ] Review `dotfiles/` structure for configuration files

### Phase 2: Core Configuration Migration

#### 2.1 Hyprland Desktop Environment
**Files to migrate:**
- `home-manager/shared/hyprland/default.nix` - Main Hyprland config
- `home-manager/shared/hyprland/` - All sub-modules

**Specific modules to convert:**
- [ ] `hyprland/default.nix` - Core Hyprland configuration
- [ ] `hyprland/rofi.nix` - Application launcher
- [ ] `hyprland/waybar.nix` - Status bar
- [ ] `hyprland/wallust.nix` - Theme management
- [ ] `hyprland/swaync.nix` - Notification center
- [ ] `hyprland/screenshot.nix` - Screenshot utilities
- [ ] `hyprland/qt5.nix` - Qt5 theme configuration
- [ ] `hyprland/qt6.nix` - Qt6 theme configuration
- [ ] `hyprland/kvantum.nix` - Kvantum theme engine
- [ ] `hyprland/ags.nix` - Advanced GTK Settings
- [ ] `hyprland/cava.nix` - Audio visualizer
- [ ] `hyprland/wlogout.nix` - Logout menu
- [ ] `hyprland/hyprlock.nix` - Screen locker

#### 2.2 Development Environment
**Files to migrate:**
- `home-manager/shared/development/default.nix`
- [ ] `development/formatters.nix` - Code formatters
- [ ] `development/languages.nix` - Programming languages
- [ ] `development/lsp-servers.nix` - Language servers

**Specific configurations:**
- [ ] Programming language installations
- [ ] LSP server configurations
- [ ] Code formatter setups

#### 2.3 Terminal & Shell
**Files to migrate:**
- [ ] `alacritty.nix` - Terminal emulator
- [ ] `ghostty.nix` - Alternative terminal
- [ ] `kitty.nix` - GPU-accelerated terminal
- [ ] `zsh.nix` - Shell configuration
- [ ] `tmux.nix` - Terminal multiplexer

#### 2.4 Applications & Tools
**Files to migrate:**
- [ ] `btop.nix` - Resource monitor
- [ ] `easyeffects.nix` - Audio effects processor
- [ ] `git.nix` - Git configuration
- [ ] `k9s.nix` - Kubernetes management
- [ ] `neovim.nix` - Text editor configuration
- [ ] `weechat.nix` - IRC client

### Phase 3: System Integration

#### 3.1 NixOS Configuration
**Files to update:**
- `hosts/nixos-desktop/config.nix` - Remove Home Manager imports
- [ ] Update system packages to include user packages
- [ ] Convert Home Manager file deployments to NixOS `environment.etc` or home directory management

#### 3.2 macOS Configuration
**Files to update:**
- [ ] `hosts/macos-macbook/config.nix` - Remove Home Manager integration

### Phase 4: Dotfiles Management

#### 4.1 Configuration File Strategy
- [ ] Decide on approach: `environment.etc`, `users.users.<name>.packages`, or custom deployment

#### 4.2 Key Dotfile Directories
- [ ] `dotfiles/hypr/` - Window manager configurations
- [ ] `dotfiles/nvim/` - Neovim configurations
- [ ] `dotfiles/zsh/` - Shell configurations
- [ ] `dotfiles/waybar/` - Status bar configurations
- [ ] `dotfiles/rofi/` - Application launcher configurations
- [ ] `dotfiles/kitty/` - Terminal configurations
- [ ] `dotfiles/ghostty/` - Alternative terminal configs

### Phase 5: Testing & Validation

#### 5.1 System Testing
- [ ] Test NixOS configuration without Home Manager
- [ ] Verify all user packages are available
- [ ] Test configuration file deployments
- [ ] Validate development environment functionality

## Migration Strategy

### Approach 1: Direct Conversion
Convert Home Manager configurations directly to NixOS/Darwin modules with:
- `environment.systemPackages` for user packages
- `environment.etc` for system-wide configuration files
- User-specific configurations via NixOS user management

### Approach 2: Custom Module System
Create a custom module system for user environment management that mimics Home Manager's functionality but uses pure Nix.

### Key Technical Decisions

#### 1. Package Management
- **Option A**: Move all user packages to `environment.systemPackages`
- **Option B**: Create user-specific package sets

#### 2. File Management
- **Option A**: Use `environment.etc` for system-wide configurations
- **Option B**: Create custom deployment scripts for user dotfiles

#### 3. State Management
- **Home Manager state**: Will be lost during migration
- **User data**: Should be preserved

#### 4. Cross-Platform Compatibility
- Maintain current structure for macOS/NixOS compatibility

## Risk Assessment

### High Risk Areas
1. **Hyprland configuration** - Complex window manager setup
2. **Development environment** - Multiple tools and configurations
3. **Shell configurations** - Zsh and related tools

### Rollback Strategy
- Keep Home Manager configurations in a backup branch
- Document manual rollback procedures

## Implementation Priority

### Critical (Must be done first)
1. Update flake configuration
2. Create backup of current state
3. Test basic configuration without Home Manager

### High Priority
1. Core desktop environment (Hyprland)
2. Shell and terminal configurations
3. Development toolchain

### Medium Priority
1. Application-specific configurations
2. Theme management systems

## Success Criteria

- [ ] System builds successfully without Home Manager
- [ ] All user packages are available
- [ ] Configuration files are properly deployed
- [ ] Development environment functions correctly
- [ ] All existing functionality preserved

## Timeline Estimate

### Phase 1: 1-2 days
### Phase 2: 3-5 days  
### Phase 3: 2-3 days
### Phase 4: 1-2 days
### Phase 5: 1-2 days

**Total Estimated Time: 8-14 days**

## Notes & Considerations

- **Configuration file paths**: Will change from `~/.config/` to system-managed locations
- **User state**: May need manual migration for some applications
- **Testing**: Each phase should be tested before proceeding

## Next Steps

1. Create a backup branch with current Home Manager configuration
2. Start with Phase 1: Flake configuration updates
3. Create minimal test configuration to validate approach
4. Incrementally migrate modules, testing at each step

---
*Last updated: $(date)*