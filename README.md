# My NixOS Config

My NixOS/Darwin Workspace setup - a unified flake for both NixOS (desktop) and macOS (laptop) using dendritic modules.

## Architecture

This configuration uses **dendritic modules** (flake-parts pattern) with an **inclusion-based architecture**:

- Each module file exports `flake.modules.nixos.<name>` and `flake.modules.darwin.<name>`
- **Import = active** — no `mkEnableOption` toggles. Importing a module enables it.
- **Roles** are import closures that transitively pull in program/service/system aspects
- Hosts import roles + infra aspects; roles import leaf aspects

```nix
# modules/programs/example/default.nix (leaf aspect — no enable option)
{ ... }:
let
  mkConfig = { isDarwin }: { config, lib, pkgs, ... }: {
    options.jvf.programs.example.username = lib.mkOption {
      type = lib.types.str;
      default = config.jvf.core.username;
    };
    config = { /* always active when imported */ };
  };
in {
  flake.modules.nixos.programs-example = mkConfig { isDarwin = false; };
  flake.modules.darwin.programs-example = mkConfig { isDarwin = true; };
}

# modules/roles/development.nix (role — import closure)
{ self, ... }:
let nixosAspects = self.modules.nixos;
in {
  flake.modules.nixos.roles-development = {
    imports = with nixosAspects; [
      programs-ghostty programs-neovim programs-zsh programs-git
    ];
  };
}
```

See `modules/hosts/nixos-desktop.nix` and `macos-macbook.nix` for full host examples.

## Structure

```
./
├── hosts/                  # Host-specific configs
├── modules/
│   ├── programs/          # Per-program modules (own folders)
│   │   ├── kitty/
│   │   ├── neovim/
│   │   └── ...
│   ├── system/            # System-level modules
│   ├── services/          # System services
│   ├── roles/             # Feature bundles
│   ├── desktop/           # Desktop environment (Hyprland)
│   ├── hardware/          # Hardware-specific
│   ├── ai-tools/          # AI tools DSL
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
