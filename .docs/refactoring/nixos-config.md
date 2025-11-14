# NixOS Host Configuration Refactoring Plan

## Overview

This document outlines the plan to refactor the `hosts/nixos-desktop/config.nix` file to extract reusable modules and minimize host-specific configuration.

## Current State

The `config.nix` file contains ~355 lines with 15 major configuration sections mixed together. The goal is to reduce the host configuration to primarily:
- Imports
- Role activations
- Module options
- Host-specific settings (hostname, hardware-specific configs)

## Analysis of Current Configuration

### ✅ Already Properly Modularized (Keep as-is)

- **Hardware modules**: bluetooth, logitech
- **Service modules**: sops, polkit, ollama, virtualisation
- **Desktop modules**: hyprland
- **Role modules**: development, gaming, media, ops-development, communication, monitoring, ai-development, network-storage

### 🔧 Sections to Extract to Modules

#### 1. Nix Daemon Configuration
**Location**: `config.nix` lines 18-34
**New Module**: `modules/system/nix-daemon.nix`

**Config to move:**
```nix
nix = {
  settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };
  optimise.automatic = true;
  gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
};
```

**Module interface:**
```nix
options.jvf.system.nix-daemon = {
  enable = mkEnableOption "Nix daemon optimization and settings";
  # Additional options for GC dates, substituters, etc.
};
```

---

#### 2. Nixpkgs Configuration
**Location**: `config.nix` lines 74-85
**New Module**: `modules/system/nixpkgs.nix`

**Config to move:**
```nix
nixpkgs = {
  config = {
    allowUnfree = true;
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "steam" "steam-original" "steam-unwrapped" "steam-run"
    ];
  };
};
```

**Module interface:**
```nix
options.jvf.system.nixpkgs = {
  enable = mkEnableOption "Nixpkgs unfree configuration";
  allowedUnfreePackages = mkOption {
    type = types.listOf types.str;
    default = [ "steam" "steam-original" "steam-unwrapped" "steam-run" ];
    description = "List of unfree packages to allow";
  };
};
```

---

#### 3. Core Networking
**Location**: `config.nix` lines 88-93
**New Module**: `modules/system/networking.nix`

**Config to move:**
```nix
networking = {
  networkmanager.enable = true;
  timeServers = options.networking.timeServers.default ++ [ "pool.ntp.org" ];
};
```

**Note**: Keep `networking.hostName = "${host}"` in the host config.

---

#### 4. Localization and Time
**Location**: `config.nix` lines 95-108
**New Module**: `modules/system/locale.nix`

**Config to move:**
```nix
time.timeZone = "America/Sao_Paulo";

i18n = {
  defaultLocale = "en_US.UTF-8";
  extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
};
```

---

#### 5. Base System Programs
**Location**: `config.nix` lines 110-126
**New Module**: `modules/system/base-programs.nix`

**Config to move:**
```nix
programs = {
  nix-ld = {
    enable = true;
    libraries = options.programs.nix-ld.libraries.default;
  };

  nm-applet.indicator = true;
  dconf.enable = true;
  seahorse.enable = true;
  fuse.userAllowOther = true;
  mtr.enable = true;
  gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
};
```

---

#### 6. Base System Services
**Location**: `config.nix` lines 177-249
**Existing Modules**: Various service configs need consolidation

**Actions:**
- Move global service configs to `modules/system/base-services.nix`
- Keep service-specific configs in their respective modules
- Examples:
  - `services.logind` → Move to `modules/services/logind.nix` or `modules/system/logind.nix`
  - `lorri.enable` → Keep in role or create dedicated module
  - `smartd.enable` → Keep as-is (hardware monitoring)
  - `pipewire` → Create `modules/services/audio.nix`
  - `flatpak` → Create `modules/services/flatpak.nix` or use existing role

---

#### 7. Security Configuration
**Location**: `config.nix` lines 295-319
**Existing Module**: `modules/services/polkit.nix`

**Actions:**
- Consolidate all security settings into existing polkit module
- OR create `modules/system/security.nix` for broader security configuration
- Move `security.rtkit`, `security.polkit`, `security.pam` to consolidated module

---

#### 8. Environment Variables
**Location**: `config.nix` lines 170-172
**New Module**: `modules/system/environment.nix`

**Config to move:**
```nix
environment.variables = {
  STEAM_EXTRA_COMPAT_TOOLS_PATHS = "$HOME/.steam/root/compatibilitytools.d";
  XDG_CONFIG_HOME = "$HOME/.config";
};
```

---

#### 9. XDG Configuration
**Location**: `config.nix` lines 258-284
**New Module**: `modules/system/xdg.nix`

**Config to move:**
```nix
xdg = {
  mime = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "org.pwmt.zathura.desktop";
      "application/epub+zip" = "org.koreader.koreader.desktop";
      # ... etc
    };
  };
  portal = {
    enable = true;
    wlr.enable = false;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    configPackages = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal ];
  };
};
```

---

#### 10. Firewall Configuration
**Location**: `config.nix` lines 325-328
**New Module**: `modules/system/firewall.nix`

**Config to move:**
```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 8000 ];
};
```

---

### 📦 System Packages Distribution Strategy

Current system packages (lines 134-168) are a mix of categories. They should be distributed:

**Keep in Host (Generic System Tools)**
```nix
environment.systemPackages = with pkgs; [
  # Core system utilities
  btrfs-progs
  cpufrequtils
  pciutils
  xdg-user-dirs
  xdg-utils

  # Filesystems
  ntfs3g

  # Indicators/libs
  glib
  gsettings-qt
  killall
  libappindicator
  libnotify
  nfs-utils

  # Optional: Keep only if truly system-wide
];
```

**Move to Roles**
- `nfs-utils, samba, sambaFull, gvfs` → `roles/network-storage.nix`
- `brave` → `roles/communication.nix` or `roles/development.nix`
- `gparted, p7zip` → `roles/development.nix` or `roles/ops-development.nix`
- `gcc, gnumake` → `roles/development.nix`
- `podman, podman-compose` → `roles/ops-development.nix` or new containers role
- `hplip` → `roles/media.nix` or hardware-specific module
- `(mpv.override { ... })` → `roles/media.nix`

---

### 🔍 Role Dependencies Analysis

Some roles lack necessary dependencies:

**network-storage Role**
- Missing: `nfs-utils`, `samba` packages
- Missing: `gvfs` service
- Action: Add to role definition

**communication Role**
- Missing: `brave` browser (currently in host config)
- Action: Add to role

**development Role**
- Missing: `gcc`, `gnumake`
- Missing: `gparted`, `p7zip`
- Action: Add to role

**ops-development Role**
- Missing: `podman`, `podman-compose`
- Action: Add to role

**gaming Role**
- Already has Steam config (✓)

**media Role**
- Missing: `mpv` with scripts
- Missing: `hplip`
- Action: Add to role

---

## Proposed Module Directory Structure

```
modules/system/
├── default.nix              # Re-exports all system modules
├── nix-daemon.nix          # Nix daemon settings
├── nixpkgs.nix             # Nixpkgs configuration
├── networking.nix          # Basic networking
├── locale.nix              # Timezone, locale
├── base-programs.nix       # dconf, gnupg, etc.
├── base-services.nix       # Common services (lorri, fstrim)
├── audio.nix               # Pipewire/wireplumber
├── security.nix            # Security/polkit/PAM
├── environment.nix         # Environment variables
├── xdg.nix                # XDG mime and portal
├── firewall.nix           # Firewall settings
├── logind.nix             # Power/login management
└── flatpak.nix            # Flatpak service
```

---

## Implementation Priority

### Phase 1: Core System Modules (High Priority)
1. `nix-daemon.nix` - Foundation for nix settings
2. `nixpkgs.nix` - Package repository config
3. `networking.nix` - Basic network setup
4. `locale.nix` - Localization settings
5. `environment.nix` - Environment variables

### Phase 2: Service Consolidation (Medium Priority)
6. `audio.nix` - Extract pipewire/wireplumber
7. `flatpak.nix` - Extract flatpak service
8. `base-services.nix` - Common service patterns
9. `logind.nix` - Power management settings
10. `security.nix` - Consolidate security configs

### Phase 3: System Packages (Low Priority)
11. Distribute system packages to respective roles
12. Add missing dependencies to roles
13. Clean up host config

### Phase 4: XDG and Firewall (Nice to have)
14. `xdg.nix` - XDG configuration
15. `firewall.nix` - Firewall settings

---

## Expected Host Configuration After Refactoring

After all refactoring is complete, the `config.nix` should be reduced to:

```nix
{ pkgs, lib, host, options, inputs, username, ... }:
let
  inherit (import ./variables.nix) gitUsername keyboardLayout;
in
{
  # === IMPORTS ===
  imports = [
    "${self}/modules/system/nix-daemon.nix"
    "${self}/modules/system/nixpkgs.nix"
    "${self}/modules/system/networking.nix"
    "${self}/modules/system/locale.nix"
    "${self}/modules/system/base-programs.nix"
    "${self}/modules/system/environment.nix"
    "${self}/modules/system/xdg.nix"
    "${self}/modules/system/firewall.nix"
    "${self}/modules/system/logind.nix"
    "${self}/modules/system/security.nix"

    "${self}/modules/services/sops.nix"
    "${self}/modules/services/polkit.nix"
    "${self}/modules/services/ollama.nix"
    "${self}/modules/services/virtualisation.nix"

    "${self}/modules/hardware/bluetooth.nix"
    "${self}/modules/hardware/logitech.nix"

    "${self}/modules/roles"
    "${self}/modules/desktop/hyprland"
    ./hardware.nix
  ];

  # === HOST-SPECIFIC CONFIGURATION ===
  networking.hostName = "${host}";

  # === MODULE ACTIVATIONS ===
  jvf.system = {
    nix-daemon.enable = true;
    nixpkgs.enable = true;
    networking.enable = true;
    locale.enable = true;
    base-programs.enable = true;
    environment.enable = true;
    xdg.enable = true;
    firewall.enable = true;
    logind.enable = true;
    security.enable = true;
  };

  jvf.services = {
    sops.enable = true;
    polkit.enable = true;
    ollama.enable = true;
    virtualisation.enable = true;
  };

  jvf.hardware = {
    bluetooth.enable = true;
    logitech.enable = true;
  };

  # === ROLE ACTIVATIONS ===
  jvf.roles = {
    development.enable = true;
    aiDevelopment.enable = true;
    opsDevelopment.enable = true;
    monitoring.enable = true;
    communication.enable = true;
    media.enable = true;
    gaming.enable = true;
    networkStorage.enable = true;
  };

  jvf.desktop.hyprland.enable = true;

  # === MINIMAL SYSTEM PACKAGES ===
  environment.systemPackages = with pkgs; [
    btrfs-progs
    cpufrequtils
    glib
    pciutils
    xdg-user-dirs
    xdg-utils
    ntfs3g
  ];

  system.stateVersion = "24.05";
}
```

**Estimated reduction**: From ~355 lines to ~75 lines (79% reduction)

---

## Migration Strategy

### Approach
1. Create new modules in `modules/system/`
2. Test each module individually
3. Gradually move configuration from host
4. Update role dependencies
5. Validate full system build
6. Commit incrementally

### Testing
- Build test: `nixos-rebuild build --flake .#nixos-desktop`
- VM test: `nixos-rebuild build-vm --flake .#nixos-desktop`
- After each phase, verify system functionality

### Rollback Plan
- Keep git commits small and atomic
- Test before each commit
- Use `nixos-rebuild switch --rollback` if issues arise

---

## Benefits

1. **Reusability**: Modules can be shared across hosts
2. **Maintainability**: Single source of truth for each feature
3. **Clarity**: Host config shows intent, not implementation
4. **Testing**: Easier to test individual modules
5. **Documentation**: Self-documenting configuration
6. **Flexibility**: Easy to enable/disable features via options
7. **Consistency**: Standardized module patterns

## Next Steps

1. Review and approve this plan
2. Prioritize phases based on needs
3. Begin implementation with Phase 1
4. Test each module as created
5. Iterate and refine module interfaces
