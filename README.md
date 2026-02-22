# My NixOS Config

My NixOS/Darwin Workspace setup - a unified flake for both NixOS (desktop) and macOS (laptop) using dendritic modules.

## Architecture

This configuration uses **dendritic modules** (flake-parts pattern) where each module file defines both NixOS and Darwin exports:

```nix
# modules/aspects/example.nix
{ ... }:
let
  mkConfig = { isDarwin }: { config, lib, pkgs, ... }:
    let cfg = config.jvf.category.example;
    in {
      options.jvf.category.example.enable = lib.mkEnableOption "Example feature";
      config = lib.mkIf cfg.enable { /* config */ };
    };
in
{
  flake.modules.nixos.example = mkConfig { isDarwin = false; };
  flake.modules.darwin.example = mkConfig { isDarwin = true; };
}
```

Hosts import these via `self.modules.{nixos,darwin}.example`. See `modules/hosts/nixos-desktop.nix` and `macos-macbook.nix` for full examples.

## Structure

```
./
├── hosts/                  # Host-specific configs
├── modules/
│   ├── aspects/           # Dendritic modules (87+ aspects)
│   │   ├── assets/        # Static configs (desktop dotfiles)
│   │   ├── programs-*.nix # App configurations
│   │   ├── system-*.nix   # System services
│   │   ├── roles-*.nix    # Feature bundles
│   │   └── ai-tools-*.nix # AI tools
│   └── hosts/             # Host selector modules
├── pkgs/                  # Custom packages
├── secrets/               # SOPS encrypted secrets
└── templates/             # Project scaffolds
```

## Install Steps

### SSH

Add or create your `id_ed25519` ssh keys running:
```console
$ ssh-keygen
```

### SOPS config:

Create the sops, age key folder:
```console
$ mkdir -p ~/.config/sops/age
```

Convert your ssh private key to age key:
```console
$ nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"
```

Generate public key from ssh public key:
```console
$ nix-shell -p ssh-to-age --run "ssh-to-age < ~/.ssh/id_ed25519.pub"
```

### MacOS

To activate the MacOS flake run for the first time:
```console
$ nix build .#darwinConfigurations.macos-macbook.system
./result/sw/bin/darwin-rebuild switch --flake .#macos-macbook
```

For updates after initial setup:
```console
$ darwin-rebuild switch --flake .#macos-macbook
```

In case you receive the error similar to `error: Build user group has mismatching GID, aborting activation`, run the following commands to fix:
```console
$ sudo dscl . -change /Groups/nixbld PrimaryGroupID 350 30000
```

### NixOS

To build and switch:
```console
$ sudo nixos-rebuild switch --flake .#nixos-desktop
```

## Known Issues

- Sometimes spotify stops working, the solution is simply remove the cache folder:
```console
$ rm -rf ~/.cache/spotify
```

## Project Templates

Common flake templates live in `templates/`:
- `sandbox-postgres-ruby/`: Rails + Postgres sandbox with process-compose helpers.
- `sandbox-postgres-django/`: Django + Postgres (PostGIS/TimescaleDB) sandbox with the same helpers.
- `frontend-bun-vite/`: Bun + Vite frontend dev shell and build/deploy scripts.
- `monorepo-subtrees/`: Subtree-oriented monorepo helpers (update/push/status apps).

## Aknowledgements
Based on [KooL's NixOS-Hyprland](https://github.com/JaKooLit/NixOS-Hyprland)
