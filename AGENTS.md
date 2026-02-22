# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-28
**Commit:** N/A (Dynamic)
**Branch:** main

> **IMPORTANT:** Before starting any implementation, read `.docs/rules.md` for project-specific lessons and gotchas.

## OVERVIEW
NixOS/Darwin unified workspace. Desktop-focused (Hyprland/macOS).
Stack: Nix flakes, SOPS (secrets), explicit module options (`jvf.*`), NO Home Manager.
Based on: KooL's NixOS-Hyprland.

## STRUCTURE
```
./
├── hosts/                   # Machine entry points (nixos/darwin)
├── modules/
│   ├── programs/            # Per-program modules (each in own folder)
│   │   ├── kitty/
│   │   │   └── default.nix  # Dendritic module (future: + assets, secrets)
│   │   ├── neovim/
│   │   ├── git/
│   │   └── ... (20 programs)
│   ├── system/              # System-level config modules
│   │   ├── networking.nix
│   │   ├── audio.nix
│   │   └── ... (16 modules)
│   ├── services/            # System services
│   │   ├── docker.nix
│   │   └── ...
│   ├── roles/               # Feature bundles (opt-in groups)
│   │   ├── desktop.nix
│   │   ├── development.nix
│   │   ├── gaming.nix
│   │   └── ... (12 roles)
│   ├── desktop/
│   │   └── hyprland/        # Hyprland desktop environment
│   │       ├── default.nix  # Main hyprland module
│   │       ├── ags.nix, rofi.nix, waybar.nix, ...
│   │       └── assets/      # Desktop config files (co-located)
│   │           ├── hypr/    # Hyprland configs
│   │           ├── rofi/    # Rofi configs + themes
│   │           ├── waybar/  # Waybar configs + styles
│   │           └── ...
│   ├── hardware/            # Hardware-specific modules
│   │   ├── amd-gpu.nix
│   │   ├── bluetooth.nix
│   │   └── ... (4 modules)
│   ├── ai-tools/            # AI tools DSL modules
│   │   ├── default.nix      # Core DSL
│   │   ├── agents.nix, commands.nix, mcp.nix, ...
│   │   └── ... (7 modules)
│   ├── boot/                # Boot configuration
│   │   └── grub-theme.nix
│   ├── core/                # Core option definitions
│   │   ├── jvf.nix          # Main jvf options (dendritic)
│   │   └── _/options.nix    # NixOS options (excluded from import-tree)
│   ├── darwin/              # macOS-specific modules
│   │   └── defaults.nix
│   ├── secrets/             # Secrets management
│   │   └── sops.nix
│   ├── hosts/               # Host configuration modules
│   │   ├── nixos-desktop.nix
│   │   └── macos-macbook.nix
│   ├── flake/               # Flake-parts configuration
│   │   └── default.nix
│   ├── overlays.nix         # Custom package overlays
│   ├── repositories.nix     # Nix repository config
│   ├── users.nix            # User definitions
│   └── wrappers.nix         # Security wrappers
├── pkgs/                    # Custom packages overlay
├── secrets/                 # SOPS encrypted secrets
├── templates/               # Project scaffolds
├── flake.nix                # Entry point (single import-tree ./modules)
└── Makefile                 # Command runner
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **New Program** | `modules/programs/<name>/default.nix` | Own folder, dendritic exports |
| **New System Module** | `modules/system/<name>.nix` | Flat in system/ |
| **New Service** | `modules/services/<name>.nix` | Flat in services/ |
| **New Role** | `modules/roles/<name>.nix` | Feature bundles |
| **Desktop Configs** | `modules/desktop/hyprland/assets/` | Co-located static configs |
| **AI Agents** | `modules/ai-tools/*.nix` | 7 dendritic modules |
| **Secrets** | `secrets/secrets.yaml` | Edit via `sops` |
| **Overlays** | `modules/overlays.nix` | Custom packages |
| **New Machine** | `hosts/<hostname>/` | Import modules in host files |

## CONVENTIONS
- **Options**: `jvf.<category>.<name>.enable` (REQUIRED for everything).
- **Naming**: Kebab-case files.
- **Imports**: Group top-level. Specific imports only (no `import ./dir`).
- **Platform**: Check `pkgs.stdenv.isDarwin` or `isDarwin` variable.
- **Formatting**: `nixpkgs-fmt` (via `make format`).

## DENDRITIC MODULE PATTERN

This project uses **flake-parts** with **dendritic** (branch-like) module organization:

- Each aspect file exports: `flake.modules.nixos.<name>` and `flake.modules.darwin.<name>`
- Host files import aspects via `self.modules.{nixos,darwin}.<name>`
- Platform detection: Use `mkConfig { isDarwin }` pattern, not `pkgs.stdenv.isDarwin`
- All options use `jvf.<category>.<name>.enable` pattern

### Adding New Module Example
```nix
# modules/programs/my-new-program/default.nix
{ ... }:
let
  mkConfig = { isDarwin }: { config, lib, pkgs, ... }:
    let cfg = config.jvf.programs.my-new;
    in {
      options.jvf.programs.my-new = {
        enable = lib.mkEnableOption "My new program";
        username = lib.mkOption {
          type = lib.types.str;
          default = "josevictor";
          description = "Username for configuration";
        };
      };
      config = lib.mkIf cfg.enable { /* config here */ };
    };
in
{
  flake.modules.nixos.my-new-program = mkConfig { isDarwin = false; };
  flake.modules.darwin.my-new-program = mkConfig { isDarwin = true; };
}
```

Then add to host files:
```nix
# modules/hosts/nixos-desktop.nix
{
  imports = with self.modules.nixos; [
    # ... other aspects
    my-new-aspect
  ];
}
```

## ANTI-PATTERNS (THIS PROJECT)
- **Home Manager**: BANNED. Use native NixOS/Darwin modules + `users.users`.
- **Implicit Enable**: NEVER enable by default. Must be opt-in.
- **Relative ../ imports**: Use absolute path from root for cross-module.
- **Old Module Style**: Don't create `modules/{programs,system,roles}/default.nix` aggregators

## COMMANDS
```bash
make format       # REQUIRED before commit
make check        # Validate structure
make rebuild      # Apply config (auto-detect OS)
make update       # Update flake inputs
make clean        # GC
```

## NOTES
- `modules/ai-tools/` is a complex module with its own DSL.
- `roles` are the preferred way to configure hosts (e.g., `jvf.roles.work.enable = true`).
