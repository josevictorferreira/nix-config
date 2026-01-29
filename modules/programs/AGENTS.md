# PROJECT KNOWLEDGE BASE

**Generated:** 2026-01-28
**Commit:** N/A (Dynamic)
**Branch:** main

## OVERVIEW
Software configuration hub. 17+ files defining user and system applications.
Handles enablement, package installation, and limited dotfile generation.

## STRUCTURE
```
modules/programs/
├── default.nix       # Aggregator
├── wezterm.nix       # Terminal
├── neovim.nix        # Editor
├── chrome.nix        # Browser
├── spotify.nix       # Media
├── yazi.nix          # File Manager
└── ...               # Individual app configs
```

## WHERE TO LOOK
- `modules/programs/default.nix`: All imports.
- `modules/programs/<app>.nix`: Specific configuration logic.

## CONVENTIONS
- **Namespace**: `jvf.programs.<name>.enable` (Required).
- **Conditionals**: Use `lib.mkIf cfg.enable`.
- **User Config**: Since HM is banned, use `jvf.wrappers` or raw config placement if needed.
- **Darwin/Linux**: Use `pkgs.stdenv.isDarwin` to guard OS-specific apps.

## ANTI-PATTERNS
- **Implicit Install**: Apps must be explicitly enabled via options.
- **Hardcoded Paths**: Use `lib.getExe` or `${pkgs.name}/bin/name`.
- **Complex Config in Nix**: Prefer sourcing external config files over large Nix strings.
