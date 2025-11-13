# Module Refactoring Plan

## Goal
Refactor logic from `hosts/nixos-desktop/config.nix` into reusable modules in the `modules/` directory, making config.nix a thin integration layer for host-specific configuration.

## Current State
- `config.nix` contains monolithic configuration (400+ lines)
- Roles already exist and import program modules
- Wrapper system (`jvf.wrappers`) already handles user package distribution
- Desktop ecosystem well-organized under `modules/desktop/hyprland/`

## Refactoring Strategy

### Phase 1: Create New Program/Service Modules

#### 1.1 Steam Module - `modules/programs/steam.nix`
**Source**: config.nix lines 119-124
```nix
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;
  dedicatedServer.openFirewall = true;
  localNetworkGameTransfers.openFirewall = true;
};
```
**Type**: Plain NixOS module (uses existing NixOS options)
**Integration**: Add to `media` role

#### 1.2 Virtualisation Module - `modules/services/virtualisation.nix`
**Source**: config.nix lines 391-396
```nix
virtualisation.libvirtd.enable = true;
virtualisation.podman = {
  enable = true;
  dockerCompat = true;
  defaultNetwork.settings.dns_enabled = true;
};
```
**Type**: Plain NixOS module
**Integration**: Add to `opsDevelopment` role

#### 1.3 Ollama Module - `modules/services/ollama.nix`
**Source**: config.nix lines 347-354
```nix
services.ollama = {
  enable = true;
  acceleration = "rocm";
  loadModels = [
    "dolphin-mixtral:8x7b"
    "goekdenizguelmez/JOSIEFIED-Qwen3:14b"
  ];
};
```
**Type**: Plain NixOS module
**Integration**: Standalone module (cross-cutting concern)

#### 1.4 Power Management Module - `modules/system/power-management.nix`
**Source**: config.nix lines 278-290
```nix
zramSwap = {
  enable = true;
  priority = 100;
  memoryPercent = 30;
  swapDevices = 1;
  algorithm = "zstd";
};

powerManagement = {
  enable = true;
  cpuFreqGovernor = "schedutil";
};
```
**Type**: Plain NixOS module
**Integration**: Standalone module (system-level concern)

### Phase 2: Extract Hardware Modules

#### 2.1 Bluetooth Module - `modules/hardware/bluetooth.nix`
**Source**: config.nix lines 296-308
```nix
hardware.bluetooth = {
  enable = true;
  powerOnBoot = true;
  settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };
};
```
**Type**: Plain NixOS module wrapper
**Integration**: Standalone hardware module

#### 2.2 Logitech Module - `modules/hardware/logitech.nix`
**Source**: config.nix lines 292-294
```nix
hardware.logitech.wireless = {
  enable = true;
  enableGraphical = false;
};
```
**Type**: Plain NixOS module wrapper
**Integration**: Standalone hardware module

### Phase 3: Distribute System Packages to Roles

**Source**: config.nix lines 142-187 (environment.systemPackages)

#### 3.1 Media Role Additions
- `pkgs.lutris`
- `pkgs.protonup-qt`
- `pkgs.wine64`
- `pkgs.winetricks`
- `pkgs.wine-wayland`
- Include Steam module from Phase 1

#### 3.2 OpsDevelopment Role Additions
- Already has k9s, awscli, kubectl, helm, helmfile
- Already has podman (from virtualisation)
- Consider adding: `pkgs.podman-compose`

#### 3.3 Development Role Additions
Missing programs to add:
```nix
programs.firefox.enable = true;
# Already has: alacritty, kitty, git, neovim, tmux, zsh
```

#### 3.4 Monitoring Role Additions
```nix
users.users."${cfg.username}".packages = [
  pkgs.baobab      # disk usage analyzer
  pkgs.duf         # disk usage/free utility
  pkgs.inxi        # system information tool
  pkgs.mtr         # network diagnostic (already enabled)
  pkgs.lsof        # list open files
  pkgs.ncdu        # NCurses Disk Usage
];
```

### Phase 4: Consolidate User Configuration

#### 4.1 Resolve User Package Duplication
**Problem**: Lines 37-56 duplicate role functionality
```nix
# Lines 37-56 - REMOVE or refactor
users.users."${username}" = {
  homeMode = "755";
  isNormalUser = true;
  description = "${gitUsername}";
  extraGroups = [ ... ];
  packages = [ ];  # Empty - handled by roles
};
```

**Solution Options**:
- **Option A**: Remove entirely, rely on roles + jvf.wrappers
- **Option B**: Create `modules/common/users.nix` with standardized setup
  ```nix
  options.jvf.users.${username} = {
    enable = lib.mkEnableOption "standard user configuration";
    extraGroups = lib.mkOption { /* ... */ };
  };
  ```

#### 4.2 Remove Redundant Program Enablers
**Lines to remove** (already handled by roles):
- Line 112: `programs.zsh.enable = true` → in development role
- Line 114: `programs.git.enable = true` → conflicts with development role!
- Line 117: `programs.virt-manager.enable = false` → in opsDevelopment
- Line 113: `programs.firefox.enable = true` → move to development role

### Phase 5: Network Storage Role Refactoring

**Current**: Lines 391-396 duplicate imports in network-storage.nix
**Improvement**: Already well-structured, just ensure config.nix imports it consistently

### Phase 6: File Structure After Refactoring

```
modules/
├── common/
│   └── users.nix                    # NEW - optional standardized user config
├── hardware/
│   ├── bluetooth.nix                # NEW
│   └── logitech.nix                 # NEW
├── programs/
│   └── steam.nix                    # NEW
├── roles/
│   ├── development.nix              # UPDATE - add firefox
│   ├── media.nix                    # UPDATE - add steam, gaming pkgs
│   └── ops-development.nix          # UPDATE - add virtualisation
├── services/
│   ├── virtualisation.nix           # NEW
│   └── ollama.nix                   # NEW
└── system/
    └── power-management.nix         # NEW
```

### Phase 7: Final config.nix Structure

After refactoring, `hosts/nixos-desktop/config.nix` should contain:

```nix
{
  # System fundamentals (keep)
  nix.settings = { ... };
  nixpkgs.config = { ... };
  system.stateVersion = "24.05";

  # Networking (keep)
  networking = { ... };
  time.timeZone = "America/Sao_Paulo";
  i18n = { ... };

  # Security (keep)
  security = { ... };
  services.logind = { ... };

  # Services (keep host-specific ones)
  services = {
    greetd = { ... };
    pipewire = { ... };
    openssh = { ... };
    # Other essential services...
  };

  # Imports - now clean and declarative
  imports = [
    # Desktop
    "${self}/modules/desktop/hyprland"

    # Hardware
    "${self}/modules/hardware/bluetooth.nix"
    "${self}/modules/hardware/logitech.nix"

    # System services
    "${self}/modules/services/ollama.nix"
    "${self}/modules/system/power-management.nix"
  ];

  # Role enablements (clear and concise)
  jvf.roles = {
    development.enable = true;
    aiDevelopment.enable = true;
    opsDevelopment.enable = true;
    media.enable = true;
    monitoring.enable = true;
    networkStorage.enable = true;
  };

  # Desktop enablement
  jvf.desktop.hyprland.enable = true;

  # Host-specific overrides (minimal)
  networking.firewall.allowedTCPPorts = [ 8000 ];
  networking.hostName = host;
}
```

### Success Metrics

- config.nix reduced from 400+ lines to ~150 lines
- All program logic lives in dedicated modules
- Roles serve as the primary way to bundle functionality
- No duplicate package definitions
- Clear separation: roles → programs → services → hardware
- Easy to enable/disable features at role level
- New hosts can reuse modules without copying config.nix

### Implementation Priority

1. ✅ Create new modules (steam, virtualisation, ollama, power-management)
2. ✅ Create hardware modules (bluetooth, logitech)
3. ✅ Update roles with additional packages
4. ✅ Remove redundant lines from config.nix
5. ✅ Test each role independently
6. ✅ Verify wrapper system works with new structure
7. ✅ Document module hierarchy and usage patterns

---

**Note**: This plan maintains backward compatibility while progressively refactoring toward a cleaner, more modular architecture. Each phase can be implemented and tested independently.
