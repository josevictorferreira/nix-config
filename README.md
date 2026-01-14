# My NixOS Config

My NixOS Workspace setup for my work desktop.

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
$ nix build .#darwinConfigurations.josevictorferreira-macos.system
./result/sw/bin/darwin-rebuild switch --flake .#josevictorferreira-macos
```

In case you receive the error similar to `error: Build user group has mismatching GID, aborting activation`, run the following commands to fix:
```console
$ sudo dscl . -change /Groups/nixbld PrimaryGroupID 350 30000
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
