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
├── modules/            # Feature modules
│   ├── common/         # Shared (ai-tools, shell, utils)
│   ├── desktop/        # UI/WM (hyprland, darwin)
│   ├── programs/       # App configs
│   ├── roles/          # Feature bundles (work, personal)
│   └── system/         # Core OS settings
├── pkgs/               # Custom packages overlay
├── secrets/            # SOPS encrypted secrets
├── templates/          # Project scaffolds
├── flake.nix           # Entry point
└── Makefile            # Command runner
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **AI Agents** | `modules/common/ai-tools/` | See sub-AGENTS.md |
| **New Machine** | `hosts/<hostname>/` | Import roles here |
| **Feature Add** | `modules/<cat>/<name>.nix` | Use `lib.mkEnableOption` |
| **Secrets** | `secrets/secrets.yaml` | Edit via `sops` |
| **Overlays** | `pkgs/default.nix` | Custom builds |

## CONVENTIONS
- **Options**: `jvf.<category>.<name>.enable` (REQUIRED for everything).
- **Naming**: Kebab-case files.
- **Imports**: Group top-level. Specific imports only (no `import ./dir`).
- **Platform**: Check `pkgs.stdenv.isDarwin` or `isDarwin` variable.
- **Formatting**: `nixpkgs-fmt` (via `make format`).

## ANTI-PATTERNS (THIS PROJECT)
- **Home Manager**: BANNED. Use native NixOS/Darwin modules + `users.users`.
- **Implicit Enable**: NEVER enable by default. Must be opt-in.
- **Relative ../ imports**: Use absolute path from root for cross-module.

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
