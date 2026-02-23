# PROJECT KNOWLEDGE BASE

**Generated:** 2026-02-23
**Commit:** N/A (Dynamic)
**Branch:** feature/dendritic-config

> **IMPORTANT:** Before starting any implementation, read `.docs/rules.md` for project-specific lessons and gotchas.

## OVERVIEW
NixOS/Darwin unified workspace. Desktop-focused (Hyprland/macOS).
Stack: Nix flakes, SOPS (secrets), explicit module options (`jvf.*`), NO Home Manager.
Based on: KooL's NixOS-Hyprland.

## STRUCTURE
```
./
├── modules/
│   ├── hosts/               # Host configurations (single source of truth)
│   │   ├── nixos-desktop/
│   │   │   ├── default.nix  # Selector + identity + config (merged)
│   │   │   └── _/hardware.nix  # Machine-specific filesystems/UUIDs
│   │   └── macos-macbook/
│   │       └── default.nix  # Selector + identity + config (merged)
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
│   ├── roles/               # Import-closure bundles (pull deps transitively)
│   │   ├── desktop.nix
│   │   ├── development.nix
│   │   ├── gaming.nix
│   │   └── ... (14 roles)
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
│   │   ├── boot.nix         # Kernel, grub, plymouth, binfmt
│   │   ├── btrfs.nix        # Btrfs autoScrub
│   │   └── ... (6 modules)
│   ├── ai-tools/            # AI tools DSL modules
│   │   ├── agents.nix, commands.nix, mcp.nix, ...
│   │   └── ... (6 modules)
│   ├── boot/                # Boot configuration
│   │   └── grub-theme.nix
│   ├── core/                # Core option definitions
│   │   ├── jvf.nix          # Main jvf options (dendritic)
│   │   └── _/options.nix    # NixOS options (excluded from import-tree)
│   ├── darwin/              # macOS-specific modules
│   │   └── defaults.nix
│   ├── secrets/             # Secrets management
│   │   └── sops.nix
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
| **Hardware/Boot** | `modules/hardware/boot.nix` | Kernel, grub, plymouth, binfmt |
| **AI Agents** | `modules/ai-tools/*.nix` | 7 dendritic modules |
| **Secrets** | `secrets/secrets.yaml` | Edit via `sops` |
| **Overlays** | `modules/overlays.nix` | Custom packages |
| **New Machine** | `modules/hosts/<hostname>/default.nix` | Selector + identity + config merged |

## CONVENTIONS
- **Architecture**: Import = active. No `mkEnableOption` on leaf modules. Roles are import closures.
- **Identity**: `config.jvf.core.username` is the single source of truth for username. NEVER hardcode `"josevictor"` in module defaults.
- **specialArgs**: Only `inputs` passed via specialArgs. Identity (username/host/os) comes from `config.jvf.core.*`, set in host config files.
- **Naming**: Kebab-case files.
- **Imports**: Group top-level. Specific imports only (no `import ./dir`).
- **Platform**: Use `mkConfig { isDarwin }` pattern, not `pkgs.stdenv.isDarwin`.
- **Formatting**: `nixpkgs-fmt` (via `make format`).

## DENDRITIC MODULE PATTERN

This project uses **flake-parts** with **dendritic** (branch-like) module organization:

- Each aspect file exports: `flake.modules.nixos.<name>` and `flake.modules.darwin.<name>`
- **Import = active** — no `mkEnableOption` on leaf modules. Importing enables them.
- Roles are import closures: `imports = with self.modules.nixos; [ prog-a prog-b ... ];`
- Host files (`modules/hosts/<name>/default.nix`) are single source of truth (selector + identity + config)
- Platform detection: Use `mkConfig { isDarwin }` pattern, not `pkgs.stdenv.isDarwin`
- Machine-specific hardware goes in `modules/hosts/<name>/_/hardware.nix` (excluded from import-tree)

### Adding New Leaf Module
```nix
# modules/programs/my-new-program/default.nix
{ ... }:
let
  mkConfig = { isDarwin }: { config, lib, pkgs, ... }: {
    options.jvf.programs.my-new.username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
    };
    config = { /* always active when imported */ };
  };
in
{
  flake.modules.nixos.programs-my-new = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-my-new = mkConfig { isDarwin = true; };
}
```

Then add to the appropriate **role** (not host):
```nix
# modules/roles/development.nix — imports pull in deps transitively
imports = with nixosAspects; [ programs-my-new ... ];
```

Or directly to host selector if not role-appropriate:
```nix
# modules/hosts/nixos-desktop/default.nix
(with self.modules.nixos; [ ... programs-my-new ... ])
```

## ANTI-PATTERNS (THIS PROJECT)
- **Home Manager**: BANNED. Use native NixOS/Darwin modules + `users.users`.
- **specialArgs for identity**: BANNED. Only `inputs` via specialArgs. Use `config.jvf.core.*` for username/host/os.
- **Hardcoded username**: BANNED. Use `config.jvf.core.username` as default in all module options.
- **Implicit Enable**: Modules activate by inclusion (import). No enable toggles on leaf modules.
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
- `roles` are import closures that pull in program/service/system aspects transitively.
- Hosts import roles; roles import leaf aspects. No enable toggles.

## HIERARCHY
Subdirectory AGENTS.md for complex modules:
- [modules/ai-tools/AGENTS.md](modules/ai-tools/AGENTS.md) — AI tools DSL
- [modules/desktop/hyprland/AGENTS.md](modules/desktop/hyprland/AGENTS.md) — Hyprland desktop
