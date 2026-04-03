# Learnings

## T1: home schema module (modules/home/default.nix)

### readOnly option + multiple setters = error
When a NixOS option is `readOnly = true`, ANY two definitions trigger "option is read-only" even if one uses `mkForce`. Solution: define the option in a shared `mkHomeOption` (options only, no config), then set it exactly once in the platform-aware `mkHomeConfig`.

### mkHomeOption must be config-free
The shared option module (`mkHomeOption`) should contain only `options.*` declarations. All `config.*` assignments (including sugar wiring, assertions, `_compiled`) belong in the platform-aware wrapper (`mkHomeConfig`) that imports `mkHomeOption`.

### Sugar shortcut wiring pattern
Sugar (files/xdg.*) uses `lib.mkIf hasSugar { ${defaultUser}.items = sugarItems; }` to merge into `jvf.home.users`. The `effectiveUsers` let-binding then merges `jvf.home.users` with the sugar for use in assertions and `_compiled` — avoids double-counting because NixOS merges the `mkIf` config before `effectiveUsers` is computed.

### Host imports required for `nix eval .#...config.*`
Adding a module to `flake.modules.nixos.*` is not enough for `nix eval .#nixosConfigurations.<host>.config.<ns>` to work — the host must explicitly import the module. Added `home` to both `nixos-desktop` and `macos-macbook` host import lists.

### pkgs.formats.yaml {} available
`pkgs.formats.yaml {}` is available in nixpkgs (unlike `lib.formats`). Same for `.json`, `.toml`, `.ini`. All four work for `_compiled` sourcePath resolution.

## T2: activation scripts (modules/home/default.nix)

### Two-level let-in for activation generation
The mkHomeConfig body uses two nested `let ... in` blocks: the first (existing) defines `effectiveUsers` and compile-time helpers, the second (new) defines `mkUserActivation`, `hasItems`, and `compiledUsers`. The second `in` then opens the module `{ imports = [...]; config = lib.mkMerge ...; }`.

### postInstall inline in bash string vs postInstallScript
The `postInstallScript` let binding was defined but ultimately not used directly — `item.postInstall` was interpolated inline in the conditionals. This is correct: postInstall runs only in the "changed" branch.

### escapeShellArg for all user-controlled paths
All Nix-computed paths interpolated into bash strings use `lib.escapeShellArg` to prevent word-splitting issues with paths containing spaces.

### compiledUsers replaces direct mapAttrs in config
T2 introduces `compiledUsers = lib.mapAttrs ... effectiveUsers` in the let block, used by both `jvf.home._compiled.users` and activation script loops. Previously `_compiled` used an inline `lib.mapAttrs` directly in config.

### lib.mkMerge([base] ++ optional ...) pattern
config block uses `lib.mkMerge ([ baseConfig ] ++ lib.optional isDarwin darwinActv ++ lib.optional (!isDarwin) nixosActv)` — exactly matches wrappers.nix pattern.
