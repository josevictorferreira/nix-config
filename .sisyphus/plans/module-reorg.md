# Module Reorganization Plan

Reorganize flat `modules/aspects/` (87 .nix files) into categorized subdirectories with per-module folders for programs.

## Target Structure
```
modules/
  programs/         # Each program gets its own folder
    kitty/default.nix
    neovim/default.nix
    git/default.nix
    ...21 programs
  system/           # System configs stay as flat .nix files
    networking.nix
    boot.nix
    ...16 files
  services/         # Service configs
    docker.nix
    ...3 files
  roles/            # Feature bundles
    desktop.nix
    ...12 files
  desktop/
    hyprland/       # Desktop environment (16+1 files)
      default.nix   # Main hyprland module
      ags.nix
      rofi.nix
      assets/       # Co-located assets (moved from aspects/assets/desktop/)
        hypr/
        rofi/
        ...
  hardware/         # Hardware configs
    nvidia.nix
    ...4 files
  ai-tools/         # AI tools DSL (7 files)
    default.nix
    agents.nix
    ...
  core/             # UNCHANGED
  hosts/            # UNCHANGED
  flake/            # UNCHANGED
  boot/             # Boot config
    grub-theme.nix
  darwin/           # Darwin-specific
    defaults.nix
  secrets/          # Secrets management
    sops.nix
  overlays.nix      # Single files stay at modules/ root
  repositories.nix
  users.nix
  wrappers.nix
```

## Phases

- [ ] Phase 1: Create dirs + move all 87 .nix files
- [ ] Phase 2: Co-locate assets with desktop/hyprland + fix relative paths
- [ ] Phase 3: Update flake.nix import-tree path
- [ ] Phase 4: Verify (nix flake check + full build)
- [ ] Phase 5: Update docs (AGENTS.md, README.md, rules.md)
- [ ] Phase 6: Commit
