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
├── hosts/              # Machine entry points (nixos/darwin)
├── modules/
│   ├── aspects/        # Dendritic flake-parts modules (flake.modules.*.*)
│   │   ├── assets/     # Static config files (desktop dotfiles)
│   │   ├── programs-*.nix   # Application configurations
│   │   ├── system-*.nix     # System services/settings
│   │   ├── roles-*.nix      # Feature bundles
│   │   └── desktop-*.nix    # Hyprland/desktop configs
│   ├── legacy/_/       # Legacy NixOS modules (being migrated)
│   ├── core/           # Core option definitions
│   └── hosts/          # Host configuration modules
├── pkgs/               # Custom packages overlay
├── secrets/            # SOPS encrypted secrets
├── templates/          # Project scaffolds
├── flake.nix           # Entry point (flake-parts)
└── Makefile            # Command runner
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **AI Agents** | `modules/aspects/ai-tools-*.nix` | 7 dendritic aspects (skills, agents, commands, etc.) |
| **New Machine** | `hosts/<hostname>/` | Import aspects in host modules |
| **New Aspect** | `modules/aspects/<name>.nix` | Export `flake.modules.{nixos,darwin}.<name>` |
| **Secrets** | `secrets/secrets.yaml` | Edit via `sops` |
| **Overlays** | `modules/aspects/overlays.nix` | Custom packages |
| **Desktop Configs** | `modules/aspects/assets/desktop/` | Static dotfiles (not Nix modules) |

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

### Adding New Aspect Example
```nix
# modules/aspects/my-new-aspect.nix
{ ... }:
let
  mkConfig = { isDarwin }: { config, lib, pkgs, ... }:
    let cfg = config.jvf.category.my-new;
    in {
      options.jvf.category.my-new = {
        enable = lib.mkEnableOption "My new feature";
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
  flake.modules.nixos.my-new-aspect = mkConfig { isDarwin = false; };
  flake.modules.darwin.my-new-aspect = mkConfig { isDarwin = true; };
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
- `modules/common/ai-tools` is a complex module with its own DSL.
- `roles` are the preferred way to configure hosts (e.g., `jvf.roles.work.enable = true`).
