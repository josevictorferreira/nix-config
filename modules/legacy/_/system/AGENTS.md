# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-28
**Commit:** N/A (Dynamic)
**Branch:** main

## OVERVIEW
Base OS configuration. Low-level hardware, networking, and security settings.
Unified Darwin/NixOS entry point.

## STRUCTURE
Flat file structure. Each file handles a specific system concern.
- `audio.nix`: Pipewire/Wireplumber.
- `base-programs.nix`: Essential CLI tools.
- `base-services.nix`: Core background daemons.
- `display.nix`: XServer/Wayland/Hyprland foundations.
- `environment.nix`: PATH, shell aliases, global vars.
- `firewall.nix`: Iptables/Nftables rules.
- `flatpak.nix`: Support for Flatpak apps.
- `locale.nix`: I18n, timezone, font settings.
- `logind.nix`: Session management, power keys.
- `networking.nix`: Hostname, Wifi, DNS.
- `nix-daemon.nix`: Nix settings (GC, experimental features).
- `nixpkgs.nix`: Unfree, config, overlays entry.
- `power-management.nix`: TLP, battery, CPU governors.
- `security.nix`: Sudo, Polkit, PAM.
- `virtualization.nix`: Docker, Podman, Libvirt.
- `xdg.nix`: Portal, user directories.

## WHERE TO LOOK
| Feature | File |
|---------|------|
| **Sound** | `audio.nix` |
| **Network** | `networking.nix` |
| **GPU/Screens** | `display.nix` |
| **Boot/Systemd** | `base-services.nix` |
| **OS Security** | `security.nix` |

## CONVENTIONS
- **Option Prefix**: `jvf.system.<name>.enable` (Required).
- **Darwin Guard**: Use `if (!isDarwin) then { ... } else { }` for Linux-only settings.
- **Default Entry**: `default.nix` aggregates all system modules via `jvf.system.modules`.
- **Hostname**: Managed via `jvf.system.hostName` and passed to `networking.nix`.

## ANTI-PATTERNS
- **Implicit Enable**: Modules MUST be explicitly listed in `jvf.system.modules`.
- **Linux-only in Darwin**: Never use `services.xserver` or `systemd` without platform check.
- **Home Manager**: Do NOT use HM here. System-wide settings only.
- **Direct Imports**: Do not import sub-modules directly in host configs; use `jvf.system.modules`.
