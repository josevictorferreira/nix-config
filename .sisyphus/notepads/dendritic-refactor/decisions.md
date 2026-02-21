
## Task 6: core-jvf aspect (2026-02-21)

- **flake.modules option**: Declared in `modules/flake/default.nix` with `lazyAttrsOf (lazyAttrsOf raw)` type — permits multiple aspect files to each contribute module sets without merge conflicts.
- **Darwin core-jvf**: Excludes hardware/default.nix (NixOS-only). Includes users/{repositories,wrappers,default}, system/default, roles/default.
- **nixpkgs.hostPlatform**: Added to darwin host modules since `darwinSystem { system = ...; }` doesn't set it, and legacy modules need pkgs for option defaults.
- **Host `self` arg**: Added `self` to host module function args to access `self.modules.{nixos,darwin}.core-jvf`.
